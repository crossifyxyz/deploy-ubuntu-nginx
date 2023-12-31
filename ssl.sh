#!/bin/bash

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Source utils.sh
source ./utils.sh

# Path to the default server configuration file
DEFAULT_SERVER_CONF="/etc/nginx/sites-available/default"
BACKUP_FILE="${DEFAULT_SERVER_CONF}.BAK"

# Get nginx server names
get_nginx_domains() {
    sudo nginx -T | grep server_name | awk '{print $2}' | tr -d ';'
}

# Certbot dry run and actual run if not in test mode
ssl_success=false
nginx_setup_needed=false

if [[ "$TEST_MODE" != "true" ]]; then
    # Certbot dry run and actual run if successful
    if sudo certbot certificates | grep -q "Domains: $DOMAINS"; then
        echo "Certbot certificate already exists for Domains: $DOMAINS"
        # Add a cron job to auto renew the Certbot certificate if not already added
    else
        sudo killall nginx
        echo "Certbot certificate not found for Domains: $DOMAINS! Running dry run..."
        sudo certbot certonly --dry-run -d $DOMAINS --email $EMAIL --agree-tos --no-eff-email --standalone
        if [ $? -eq 0 ]; then
            echo "Dry run successful for $DOMAINS! Running certbot..."
            sudo certbot --nginx -d $DOMAINS --email $EMAIL --agree-tos --no-eff-email
            ssl_success=true
        else
            echo "Dry run failed for $DOMAINS!"
        fi
    fi
else
    echo "Skipping Certbot dry run and actual run in test mode"
fi

run_nginx_setup() {
    sudo killall nginx
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

    echo "Nginx configuration updated!"
}

# if Nginx domains are different from .env domains, setup needed
nginx_domains=$(get_nginx_domains)
if [[ "$nginx_domains" != "$DOMAINS" ]]; then
    nginx_setup_needed=true
fi

# if Certbot run was successful or Nginx setup needed, run long lasting funcs
if [[ "$ssl_success" == "true" ]] || [[ "$nginx_setup_needed" == "true" ]]; then
    # Run nginx setup
    run_nginx_setup
else
    echo "Skipping NGINX Setup and Certbot renew cron job"
fi

sudo systemctl restart nginx

if sudo certbot certificates | grep -q "No certificates found."; then
    echo "No live certificates."
else
    echo "There are some live certificates"
    add_cron_job_renew
fi
