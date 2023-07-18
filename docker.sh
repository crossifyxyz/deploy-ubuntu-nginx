#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Run the Docker container if not already running
if docker ps --filter "name=$DOCKER_PROCESS_NAME" --format '{{.Names}}' | grep -q "$DOCKER_PROCESS_NAME"; then
    echo "Docker container is already running, updating"
    # Authenticate Docker to AWS ECR
    aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI

    # Pull the latest image from AWS ECR
    echo "Pulling latest image from AWS ECR..."
    docker pull $ECR_URI

    # Restart the Docker container with the new image using zero-downtime
    echo "Restarting Docker container"
    docker restart $DOCKER_PROCESS_NAME
else
    # Check if the image is already pulled
    if docker image inspect $ECR_URI &>/dev/null; then
        echo "Docker process not found! Starting..."
        docker run -d -p $DEPLOY_PORT:$DEPLOY_PORT --env-file $(pwd)/.env.docker --name $DOCKER_PROCESS_NAME $ECR_URI
    else
        # Authenticate Docker to AWS ECR
        aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI
        
        # Pull the latest image from AWS ECR
        docker pull $ECR_URI
        docker run -d -p $DEPLOY_PORT:$DEPLOY_PORT --env-file $(pwd)/.env.docker --name $DOCKER_PROCESS_NAME $ECR_URI
    fi
fi

docker update --restart=unless-stopped $DOCKER_PROCESS_NAME
