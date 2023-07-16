#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Authenticate Docker to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ECR_ID

# Pull the latest image from AWS ECR
echo "Pulling latest image from AWS ECR..."
docker pull $AWS_ECR_ID

# Delete the old PM2 process
echo "Deleting the old PM2 process..."
pm2 stop $PM2_PROCESS_NAME
pm2 delete $PM2_PROCESS_NAME

# Start the new PM2 process with the latest Docker image
echo "Starting the new PM2 process with the latest Docker image..."
pm2 start "docker run -d -p $DEPLOY_PORT:80 --env-file .env.docker" --name $PM2_PROCESS_NAME

echo "Update completed!"
