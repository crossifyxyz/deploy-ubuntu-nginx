#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Prompt to update
read -p "Do you want to update the system? (y/n): " update_conf
if [[ $update_conf == "y" ]]; then
    # Update the system
    echo "Updating the System"
    sudo apt update
fi

# Install NVM if not present
if ! [ -d "${HOME}/.nvm/.git" ]; then
    echo "NVM not found! Installing..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    source $HOME/.bashrc
else
    echo "NVM is already installed"
fi

# Install NODE if not present
if ! command -v node &>/dev/null; then
    echo "NODE not found! Installing..."
    nvm install --lts
else
    echo "NODE is already installed"
fi

# Install Docker if not present
if ! command -v docker &>/dev/null; then
    echo "Docker not found! Installing..."
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    apt-cache policy docker-ce
    sudo apt install docker-ce
    sudo groupadd docker
    sudo usermod -aG docker ${USER}
    newgrp docker
else
    echo "Docker is already installed"
fi

# Install Nginx if not present
if [[ "$TEST_MODE" != "true" ]] && ! command -v nginx &>/dev/null; then
    echo "Nginx not found! Installing..."
    sudo apt install -y nginx
    sudo killall nginx
else
    echo "Nginx is already installed"
fi

# Install Certbot if not present
if [[ "$TEST_MODE" != "true" ]] && ! command -v certbot &>/dev/null; then
    echo "Certbot not found! Installing..."
    if ! command -v snapd &>/dev/null; then
        echo "SNAP not found! Installing..."
        sudo apt install snapd
    fi
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
else
    echo "Certbot is already installed"
fi

# Install AWS CLI if not present
if ! command -v aws &>/dev/null; then
    echo "AWS CLI not found! Installing..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    if ! command -v unzip &>/dev/null; then
        echo "Unzip not found! Installing..."
        sudo apt install unzip
    fi
    unzip awscliv2.zip
    sudo ./aws/install
else
    echo "AWS CLI is already installed"
fi

# Install PM2 if not present
if ! command -v pm2 &>/dev/null; then
    echo "PM2 not found! Installing..."
    sudo npm install -g pm2
else
    echo "PM2 is already installed"
fi
