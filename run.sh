#!/bin/bash

exec > >(tee -ia cli.log)
exec 2> >(tee -ia cli.log >&2)

# Function to prompt the user to paste environment variables block and create the file
prompt_and_create_env_file() {
    file=$1

    echo "$file file not found!"
    echo "Please paste the block of environment variables code and press Enter:"
    read -r -d '' env_block
    echo "$env_block" > "$file"
    echo "$file file created with the provided environment variables."
}

# Check if .env file exists
if [ ! -f ".env" ]; then
    prompt_and_create_env_file ".env"
fi

# Check if .env.docker file exists
if [ ! -f ".env.docker" ]; then
    prompt_and_create_env_file ".env.docker"
fi

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Source utils.sh
source ./utils.sh

# Make install.sh and setup.sh executable
chmod +x install.sh
chmod +x setup.sh
chmod +x ssl.sh
chmod +x swap.sh
chmod +x docker.sh
chmod +x utils.sh

# Function to configure swap space
configure_swap_space() {
    read -p "Do you want to configure swap space? (y/n): " configure_swap
    if [[ $configure_swap == "y" ]]; then
        run_script "swap.sh"
    fi
}

# Function to remove all cron jobs
remove_all_cron_jobs() {
    echo "Removing all cron jobs..."
    sudo crontab -r
    echo "All cron jobs removed."
}

# Prompt for user input
echo "Select an option:"
echo "1. Full setup"
echo "2. Update"
echo "3. Install"
echo "4. Setup"
echo "5. SSL"
echo "6. Run Docker"
echo "7. Restart Docker"
echo "8. View Docker logs"
echo "9. Kill all Docker"
echo "10. Disable Docker on startup"
echo "11. Configure Swap Space"
echo "12. Add all cron jobs"
echo "13. Kill all cron jobs"

read -p "Enter your choice (1-14): " choice

# Execute the selected option
case $choice in
1)
    configure_swap_space
    run_script "install.sh"
    run_script "setup.sh"
    ;;
2)
    update_docker_container
    ;;
3)
    run_script "install.sh"
    ;;
4)
    run_script "setup.sh"
    ;;
5)
    run_script "ssl.sh"
    ;;
6)
    run_script "docker.sh"
    ;;
7)
    restart_docker_container
    ;;
8)
    docker logs $DOCKER_PROCESS_NAME
    ;;
9)
    docker rm -f $(docker ps -aq)
    ;;
10)
    docker update --restart=no $DOCKER_PROCESS_NAME
    ;;
11)
    configure_swap_space
    ;;
12)
    add_cron_job_renew
    add_cron_job_update
    ;;
13)
    remove_all_cron_jobs
    ;;
*)
    echo "Invalid choice. Exiting..."
    exit 1
    ;;
esac

# Finish the terminal prompts
echo "Run completed!"
