#!/bin/bash

# Source utils.sh
source ./utils.sh

# Define the ECR repository name
ECR_REPOSITORY_NAME=$(echo $ECR_URI | cut -d'/' -f2 | cut -d':' -f1)

# Define the image tag
IMAGE_TAG=$(echo $ECR_URI | cut -d':' -f2)

# Check if the Docker container exists
if docker ps -a --filter "name=$DOCKER_PROCESS_NAME" --format '{{.Names}}' | grep -q "$DOCKER_PROCESS_NAME"; then
    # Get the local version and convert to epoch time
    local_version=$(docker image inspect ${ECR_URI} --format='{{.Created}}' | date -u --iso-8601=seconds -f- | date +%s)

    # Get the remote version and convert to epoch time
    remote_version=$(aws ecr describe-images --repository-name $ECR_REPOSITORY_NAME --image-ids imageTag=$IMAGE_TAG --query 'sort_by(imageDetails,& imagePushedAt)[-1].imagePushedAt' --output text | date -u --iso-8601=seconds -f- | date +%s)

    echo "Docker container found, updating..."
    # Compare versions
    if [[ "$local_version" -lt "$remote_version" ]]; then
        echo "Local version ($local_version) is older than remote version ($remote_version). Pulling the new image..."
        echo "Removing old Docker container..."
        docker rm -f $DOCKER_PROCESS_NAME
        auth_aws
        echo "Pulling latest image from AWS ECR..."
        docker pull $ECR_URI
        run_docker_container
    else
        echo "Local version ($local_version) is up to date. No action required."
    fi
else
    echo "Docker process not found!"
    # Check if the image is already pulled
    if docker image inspect $ECR_URI &>/dev/null; then
        echo "Docker image found. Skipping pull..."
        run_docker_container
    else
        auth_aws
        echo "Pulling latest image from AWS ECR..."
        docker pull $ECR_URI
        run_docker_container
    fi
fi

# Add a cron job to check for updates every 30 minutes
add_cron_job_update