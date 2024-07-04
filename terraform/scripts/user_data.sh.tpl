#!/bin/bash

# Persist environment variables
echo "export DB_NAME=${db_name}" | sudo tee -a /etc/profile.d/custom_env_vars.sh
echo "export DB_USER=${db_username}" | sudo tee -a /etc/profile.d/custom_env_vars.sh
echo "export DB_PASSWORD=${db_password}" | sudo tee -a /etc/profile.d/custom_env_vars.sh
echo "export DB_HOST=${db_endpoint}" | sudo tee -a /etc/profile.d/custom_env_vars.sh
echo "export CACHE_HOST=${redis_endpoint}" | sudo tee -a /etc/profile.d/custom_env_vars.sh

# Update the system
sudo apt-get update -y

# Ensure Apache, MariaDB, and PHP-FPM services are running
sudo /opt/bitnami/ctlscript.sh start

# Install PECL and Redis PECL extension
sudo apt-get install -y php-pear php-dev
sudo pecl install redis

# Enable Redis extension in PHP
sudo bash -c 'echo "extension=redis.so" >> /opt/bitnami/php/etc/php.ini'

# Replace existing session.save_handler and session.save_path in PHP
sudo sed -i "s|session.save_handler = .*|session.save_handler = redis|" /opt/bitnami/php/etc/php.ini
sudo sed -i "s|session.save_path = .*|session.save_path = \"tls://${redis_endpoint}:6379\"|" /opt/bitnami/php/etc/php.ini

# Configure WordPress
cd /opt/bitnami/wordpress

# Set database configuration using environment variables
sudo sed -i "s/define( 'DB_NAME', .*);/define( 'DB_NAME', getenv('DB_NAME') );/" wp-config.php
sudo sed -i "s/define( 'DB_USER', .*);/define( 'DB_USER', getenv('DB_USER') );/" wp-config.php
sudo sed -i "s/define( 'DB_PASSWORD', .*);/define( 'DB_PASSWORD', getenv('DB_PASSWORD') );/" wp-config.php
sudo sed -i "s/define( 'DB_HOST', .*);/define( 'DB_HOST', getenv('DB_HOST') );/" wp-config.php

# Restart Apache to apply changes
sudo /opt/bitnami/ctlscript.sh restart apache
