#!/bin/bash

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