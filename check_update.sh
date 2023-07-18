#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Source utils.sh
source ./utils.sh

# Get the dir as an argument
DIR_ARG="$1"

# Define the ECR repository name
ECR_REPOSITORY_NAME=$(echo $ECR_URI | cut -d'/' -f2 | cut -d':' -f1)

# Define the image tag
IMAGE_TAG=$(echo $ECR_URI | cut -d':' -f2)

# Check if the image exists locally
if docker image inspect ${ECR_URI} &>/dev/null; then
    # Get the local version and convert to epoch time
    local_version=$(docker image inspect ${ECR_URI} --format='{{.Created}}' | date -u --iso-8601=seconds -f- | date +%s)

    # Get the remote version and convert to epoch time
    remote_version=$(aws ecr describe-images --repository-name $ECR_REPOSITORY_NAME --image-ids imageTag=$IMAGE_TAG --query 'sort_by(imageDetails,& imagePushedAt)[-1].imagePushedAt' --output text | date -u --iso-8601=seconds -f- | date +%s)

    # Compare versions
    if [[ "$local_version" -lt "$remote_version" ]]; then
        echo "Local version ($local_version) is older than remote version ($remote_version). Pulling the new image..."
        # Execute the docker.sh script
        run_script "$DIR_ARG/docker.sh"
    else
        echo "Local version ($local_version) is up to date. No action required."
    fi
else
    echo "Docker image not found locally."
fi
