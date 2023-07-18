#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

sudo killall nginx

# Path to the default server configuration file
DEFAULT_SERVER_CONF="/etc/nginx/sites-available/default"
BACKUP_FILE="${DEFAULT_SERVER_CONF}.BAK"

# Check if in test mode
if [[ "$TEST_MODE" != "true" ]]; then
    # Backup the existing default server configuration file
    if [ ! -f "$BACKUP_FILE" ]; then
        sudo cp $DEFAULT_SERVER_CONF $BACKUP_FILE
        echo "Backup created: $BACKUP_FILE"
    else
        echo "Backup file $BACKUP_FILE already exists"
    fi

    # Get the first domain from the DOMAINS environment variable
    DOMAIN=$(echo $DOMAINS | awk '{print $1}')

    # Create a temporary copy of def-server-conf for modifications
    cp def-server-conf def-server-conf-temp

    # Replace the placeholders in the temporary file with the corresponding values from .env
    sed -i "s/server_name_placeholder/$DOMAINS/g" def-server-conf-temp
    sed -i "s/first_domain_placeholder/$DOMAIN/g" def-server-conf-temp
    sed -i "s/proxy_pass_placeholder/http:\/\/localhost:$DEPLOY_PORT/g" def-server-conf-temp

    # Move the modified temporary file to the Nginx sites-available directory
    sudo cp def-server-conf-temp $DEFAULT_SERVER_CONF

    # Remove the temporary file
    rm def-server-conf-temp

    # Restart Nginx to apply the changes
    sudo systemctl restart nginx

    echo "Nginx configuration updated!"
else
    echo "Skipping Nginx configuration update in test mode"
fi
