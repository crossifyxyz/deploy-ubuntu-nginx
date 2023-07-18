#!/bin/bash

exec > >(tee -ia cli.log)
exec 2> >(tee -ia cli.log >&2)

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo ".env file not found!"
    echo "Please make sure to create the .env file with the required environment variables."
    exit 1
fi

# Check if .env.docker file exists
if [ ! -f ".env.docker" ]; then
    echo ".env.docker file not found!"
    echo "Please make sure to create the .env.docker file with the required environment variables."
    exit 1
fi

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Source utils.sh
source ./utils.sh

# Make install.sh and setup.sh executable
chmod +x install.sh
chmod +x setup.sh
chmod +x update.sh
chmod +x nginx.sh
chmod +x swap.sh
chmod +x check_update.sh
chmod +x docker.sh

# Function to configure swap space
configure_swap_space() {
    read -p "Do you want to configure swap space? (y/n): " configure_swap
    if [[ $configure_swap == "y" ]]; then
        run_script "swap.sh"
    fi
}

# Prompt for user input
echo "Select an option:"
echo "1. Full setup"
echo "2. Update"
echo "3. Install"
echo "4. Setup"
echo "5. Nginx"
echo "6. Run Docker"
echo "7. Restart Docker"
echo "8. View Docker logs"
echo "9. Kill all Docker"
echo "10. Disable Docker on startup"
echo "11. Cancel Certbot cron job"
echo "12. Configure Swap Space"
echo "13. Cancel Docker check update cron job"

read -p "Enter your choice (1-13): " choice

# Execute the selected option
case $choice in
1)
    configure_swap_space
    run_script "install.sh"
    run_script "setup.sh"
    ;;
2)
    run_script "update.sh"
    ;;
3)
    run_script "install.sh"
    ;;
4)
    run_script "setup.sh"
    ;;
5)
    run_script "nginx.sh"
    ;;
6)
    run_script "docker.sh"
    ;;
7)
    docker restart $DOCKER_PROCESS_NAME
    ;;
8)
    docker logs --follow $DOCKER_PROCESS_NAME
    ;;
9)
    docker rm -f $(docker ps -aq)
    ;;
10)
    docker update --restart=no $DOCKER_PROCESS_NAME
    ;;
11)
    sudo crontab -l | grep -v "/usr/bin/certbot renew --quiet" | sudo crontab -
    ;;
12)
    configure_swap_space
    ;;
13)
    sudo crontab -l | grep -v "$(pwd)/check_update.sh" | sudo crontab -
    ;;
*)
    echo "Invalid choice. Exiting..."
    exit 1
    ;;
esac

# Finish the terminal prompts
echo "Run completed!"
