#!/bin/bash

# Make install.sh and setup.sh executable
chmod +x install.sh
chmod +x setup.sh
chmod +x update.sh

# Function to run a script and log its output
run_script() {
    script=$1
    log_file=$2
    
    echo "Running $script..."
    bash $script | tee -a $log_file
    echo "$script completed. Output logged to $log_file"
}

# Run install.sh and log output
run_script "install.sh" "install.log"

# Run setup.sh and log output
run_script "setup.sh" "setup.log"

# Function to print and forward all output to the terminal
print_and_forward_output() {
    log_file=$1
    tail -f $log_file &
    tail_pid=$!
    
    trap "kill $tail_pid" EXIT
    wait $tail_pid
}

# Print and forward output from install.log
echo "Printing and forwarding output from install.log..."
print_and_forward_output "install.log"

# Print and forward output from setup.log
echo "Printing and forwarding output from setup.log..."
print_and_forward_output "setup.log"

# Finish the terminal prompts
echo "Installation and setup completed. Press any key to exit."
read -n 1 -s -r -p ""