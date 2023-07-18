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
    read -p "Do you want to configure AWS credentials again? (y/n): " configure_again
    if [[ $configure_again == "y" ]]; then
        # Run aws configure
        aws configure
    fi
fi

# Authenticate Docker to AWS ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI

# Check if the image is already pulled
if docker image ls | grep -q $ECR_URI; then
    read -p "The Docker image is already pulled. Do you want to pull it again? (y/n): " pull_again
    if [[ $pull_again == "y" ]]; then
        # Pull the latest image from AWS ECR
        docker pull $ECR_URI
    fi
else
    # Pull the latest image from AWS ECR
    docker pull $ECR_URI
fi

# Run the Certbot dry run and actual run if not in test mode
certbot_failed=false
if [[ "$TEST_MODE" != "true" ]]; then
    # Certbot dry run and actual run if successful
    first_domain=$(echo "$DOMAINS" | awk '{print $1}')
    if [ -d "/etc/letsencrypt/live/$first_domain" ]; then
        echo "Certbot certificate already exists for $first_domain"
    else
        echo "Certbot certificate not found for $first_domain! Running dry run..."
        sudo certbot certonly --dry-run -d $DOMAINS --email $EMAIL --agree-tos --no-eff-email
        if [ $? -eq 0 ]; then
            echo "Dry run successful for $DOMAINS! Running certbot..."
            sudo certbot --nginx -d $DOMAINS --email $EMAIL --agree-tos --no-eff-email
        else
            echo "Dry run failed for $DOMAINS!"
            certbot_failed=true
        fi
    fi
else
    echo "Skipping Certbot dry run and actual run in test mode"
    certbot_failed=true
fi

# Run the Docker container if not already running
if docker ps --filter "name=$DOCKER_PROCESS_NAME" --format '{{.Names}}' | grep -q "$DOCKER_PROCESS_NAME"; then
    echo "Docker container is already running"
else
    echo "Docker container not found! Starting..."
    docker run -d -p $DEPLOY_PORT:$DEPLOY_PORT --env-file $(pwd)/.env.docker --name $DOCKER_PROCESS_NAME $ECR_URI
fi

# Run Docker consist if not in test mode
if [[ "$TEST_MODE" == "false" ]]; then
    # Configure Docker to start the container on system startup
    echo "Configuring Docker container to run on startup..."
    docker update --restart=unless-stopped $DOCKER_PROCESS_NAME
else
    echo "Skipping Docker container to run on startup in test mode"
fi

if [[ "$certbot_failed" != "true" ]]; then
    # Run nginx.sh
    echo "Running nginx.sh..."
    bash nginx.sh
    echo "nginx.sh completed."
    # Add a cron job to auto renew the Certbot certificate if not already added
    CRON_JOB="0 12 * * * /usr/bin/certbot renew --quiet"
    if ! crontab -l | grep -q "$CRON_JOB"; then
        echo "$CRON_JOB" | sudo tee -a /var/spool/cron/crontabs/root
    else
        echo "Cron job already added"
    fi
else
    echo "Skipping cron job and NGINX Setup in test mode or when Certbot run failed"
fi

echo "Setup finalized!"
