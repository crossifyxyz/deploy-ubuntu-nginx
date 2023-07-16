#!/bin/bash

# Make install.sh and setup.sh executable
chmod +x install.sh
chmod +x setup.sh
chmod +x update.sh

# Run install.sh and log output
echo "Running install.sh..."
bash install.sh > install.log 2>&1
echo "install.sh completed. Output logged to install.log"

# Run setup.sh and log output
echo "Running setup.sh..."
bash setup.sh > setup.log 2>&1
echo "setup.sh completed. Output logged to setup.log"