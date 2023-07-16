#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Authenticate Docker to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ECR_ID

# Pull the latest image from AWS ECR
docker pull $AWS_ECR_ID

# Certbot dry run and actual run if successful
for domain in $DOMAINS
do
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        echo "Certbot certificate already exists for $domain"
    else
        echo "Certbot certificate not found for $domain! Running dry run..."
        sudo certbot certonly --nginx --dry-run -d $domain --email $EMAIL --agree-tos --no-eff-email
        if [ $? -eq 0 ]
        then
            echo "Dry run successful for $domain! Running certbot..."
            sudo certbot --nginx -d $domain --email $EMAIL --agree-tos --no-eff-email
        else
            echo "Dry run failed for $domain!"
        fi
    fi
done

# Run the Docker container using PM2 if not already running
if pm2 describe $PM2_PROCESS_NAME > /dev/null
then
    echo "PM2 process is already running"
else
    echo "PM2 process not found! Starting..."
    pm2 start "docker run -d -p $DEPLOY_PORT:80 --env-file .env.docker $AWS_ECR_ID" --name $PM2_PROCESS_NAME
fi

# Make PM2 run on startup and run all services in PM2 on startup
pm2 startup
pm2 save

# Add a cron job to auto renew the Certbot certificate if not already added
CRON_JOB="0 12 * * * /usr/bin/certbot renew --quiet"
if ! crontab -l | grep -q "$CRON_JOB"; then
    echo "$CRON_JOB" | sudo tee -a /var/spool/cron/crontabs/root
fi
