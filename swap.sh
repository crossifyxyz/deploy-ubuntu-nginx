#!/bin/bash

# Check if swap is already set up
if [[ -n $(sudo swapon --show) ]]; then
    echo "Swap is already set up."
    read -p "Do you want to resize the swap space? (y/n): " resize_swap
    if [[ $resize_swap == "y" ]]; then
        read -p "Enter the new swap size in GB (e.g., 12): " SWAP_GB
        resize_swap=true
    else
        resize_swap=false
    fi
else
    read -p "Enter the swap size in GB (e.g., 12): " SWAP_GB
    resize_swap=false
fi

if [[ $resize_swap == true ]]; then
    echo "Resizing the Swap File"
    sudo swapoff /swapfile
    sudo rm /swapfile
    sudo fallocate -l ${SWAP_GB}G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
else
    echo "Creating a Swap File"
    sudo fallocate -l ${SWAP_GB}G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
fi

echo "Swap space setup completed."

# Make the Swap File Permanent
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tune Swap Settings
sudo sysctl vm.swappiness=10
sudo sed -i '1i vm.swappiness=10' /etc/sysctl.conf
sudo sysctl vm.vfs_cache_pressure=50
sudo sed -i '1i vm.vfs_cache_pressure=50' /etc/sysctl.conf
