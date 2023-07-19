#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Get the current directory path
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

# Function to run a script
run_script() {
    script=$1

    echo "Running $script..."
    if bash $script; then
        echo "$script completed."
    else
        echo "$script failed. Exiting..."
        exit 1
    fi
}

# Function to add a cron job
add_cron_job() {
    cron_job=$1
    if ! sudo crontab -l | grep -q "$cron_job"; then
        echo "$cron_job" | sudo tee -a /var/spool/cron/crontabs/root
        echo "Cron job added: $cron_job"
    else
        echo "Cron job already exists: $cron_job"
    fi
}

# Function to remove a cron job
remove_cron_job() {
    cron_job=$1
    if sudo crontab -l | grep -q "$cron_job"; then
        sudo crontab -l | grep -v "$cron_job" | sudo crontab -
        echo "Cron job removed: $cron_job"
    else
        echo "Cron job does not exist: $cron_job"
    fi
}

# Authenticate Docker to AWS ECR
auth_aws() {
    aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI
}

# Run the Docker container
run_docker_container() {
    echo "Starting Docker container..."
    docker run -d -p $DEPLOY_PORT:$DEPLOY_PORT --env-file "$CURRENT_DIR/.env.docker" --name $DOCKER_PROCESS_NAME $ECR_URI
    docker update --restart=unless-stopped $DOCKER_PROCESS_NAME
}

restart_docker_container() {
    echo "Removing old Docker container..."
    docker rm -f $DOCKER_PROCESS_NAME
    run_docker_container
}