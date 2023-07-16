#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Check if AWS credentials are already configured
if ! aws configure get aws_access_key_id &>/dev/null && ! aws configure get aws_secret_access_key &>/dev/null; then
    # AWS credentials not configured, run aws configure
    echo "AWS credentials not found! Running AWS configure..."
    aws configure
else
    echo "AWS credentials are already configured"

    # Prompt to configure again
    read -p "Do you want to configure AWS credentials again? (yes/no): " configure_again
    if [[ $configure_again == "yes" ]]; then
        # Run aws configure
        aws configure
    fi
fi

# Authenticate Docker to AWS ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI

# Pull the latest image from AWS ECR
docker pull $ECR_URI

# Run the Certbot dry run and actual run if not in test mode
if [[ "$TEST_MODE" != "true" ]]; then
    # Certbot dry run and actual run if successful
    for domain in $DOMAINS; do
        if [ -d "/etc/letsencrypt/live/$domain" ]; then
            echo "Certbot certificate already exists for $domain"
        else
            echo "Certbot certificate not found for $domain! Running dry run..."
            sudo certbot certonly --nginx --dry-run -d $domain --email $EMAIL --agree-tos --no-eff-email
            if [ $? -eq 0 ]; then
                echo "Dry run successful for $domain! Running certbot..."
                sudo certbot --nginx -d $domain --email $EMAIL --agree-tos --no-eff-email
            else
                echo "Dry run failed for $domain!"
            fi
        fi
    done
else
    echo "Skipping Certbot dry run and actual run in test mode"
fi

# Run the Docker container using PM2 if not already running
if pm2 describe $PM2_PROCESS_NAME >/dev/null; then
    echo "PM2 process is already running"
else
    echo "PM2 process not found! Starting..."
    pm2 start "docker run -d -p $DEPLOY_PORT:80 --env-file $(pwd)/.env.docker $ECR_URI" --name $PM2_PROCESS_NAME
fi

# Run pm2 consist if not in test mode
if [[ "$TEST_MODE" == "false" ]]; then
    # Make PM2 run on startup and run all services in PM2 on startup
    pm2 startup
    pm2 save
else
    echo "Skipping pm2 consist in test mode"
fi

# Add a cron job to auto renew the Certbot certificate if not already added
CRON_JOB="0 12 * * * /usr/bin/certbot renew --quiet"
if [[ "$TEST_MODE" != "true" ]]; then
    if ! crontab -l | grep -q "$CRON_JOB"; then
        echo "$CRON_JOB" | sudo tee -a /var/spool/cron/crontabs/root
    else
        echo "Cron job already added"
    fi
else
    echo "Skipping cron job in test mode"
fi

echo "Setup finalized!"
