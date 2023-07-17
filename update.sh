#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Authenticate Docker to AWS ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI

# Pull the latest image from AWS ECR
echo "Pulling latest image from AWS ECR..."
docker pull $ECR_URI

# Delete the old PM2 process
echo "Restarting PM2 process..."
pm2 restart $PM2_PROCESS_NAME --update-env

echo "Update completed!"