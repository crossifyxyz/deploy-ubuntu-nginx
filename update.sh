#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Authenticate Docker to AWS ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI

# Pull the latest image from AWS ECR
echo "Pulling latest image from AWS ECR..."
docker pull $ECR_URI

# Restart the Docker container with the new image using zero-downtime
echo "Restarting Docker container"
docker restart $DOCKER_PROCESS_NAME

echo "Update completed!"