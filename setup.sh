#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Source utils.sh
source ./utils.sh

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

# Run the Docker
run_script "docker.sh"

# Run SSL
run_script "ssl.sh"


# Add a cron job to check for updates every 30 minutes
if [[ "$TEST_MODE" != "true" ]]; then
    add_cron_job "*/30 * * * * $CURRENT_DIR/check_update.sh $CURRENT_DIR"
else
    echo "Skipping check update cron job in test mode"
fi
