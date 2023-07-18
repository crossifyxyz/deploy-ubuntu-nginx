#!/bin/bash

# Get the current directory path
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Run the Docker container if not already running
if docker ps --filter "name=$DOCKER_PROCESS_NAME" --format '{{.Names}}' | grep -q "$DOCKER_PROCESS_NAME"; then
    echo "Docker container is already running"
else
    echo "Docker container not found! Starting..."
    docker run -d -p $DEPLOY_PORT:$DEPLOY_PORT --env-file $(pwd)/.env.docker --name $DOCKER_PROCESS_NAME --log-driver json-file --log-opt max-size=10m --log-opt max-file=5 $ECR_URI
fi
