#!/bin/bash

# Get the current directory path
CURRENT_DIR=$(dirname "$(readlink -f "$0")")

CRON_JOB_UPDATE="*/30 * * * * $CURRENT_DIR/check_update.sh $CURRENT_DIR"
CRON_JOB_CERTBOT="0 12 * * * /usr/bin/certbot renew --quiet --non-interactive"

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
    if ! crontab -l | grep -q "$cron_job"; then
        echo "$cron_job" | sudo tee -a /var/spool/cron/crontabs/root
        echo "Cron job added: $cron_job"
    else
        echo "Cron job already exists: $cron_job"
    fi
}

# Function to remove a cron job
remove_cron_job() {
    cron_job=$1
    if crontab -l | grep -q "$cron_job"; then
        sudo crontab -l | grep -v "$cron_job" | sudo crontab -
        echo "Cron job removed: $cron_job"
    else
        echo "Cron job does not exist: $cron_job"
    fi
}