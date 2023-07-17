#!/bin/bash

# Make install.sh and setup.sh executable
chmod +x install.sh
chmod +x setup.sh
chmod +x update.sh
chmod +x nginx.sh

# Function to run a script
run_script() {
    script=$1
    
    echo "Running $script..."
    bash $script
    echo "$script completed."
}

# Prompt for user input
echo "Select an option:"
echo "1. Full setup"
echo "2. Update"
echo "3. Install"
echo "4. Setup"
echo "5. Nginx"

read -p "Enter your choice (1-5): " choice

# Execute the selected option
case $choice in
    1)
        run_script "install.sh"
        run_script "setup.sh"
        run_script "nginx.sh"
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
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

# Finish the terminal prompts
echo "Installation and setup completed. Press any key to exit."
read -n 1 -s -r -p ""
