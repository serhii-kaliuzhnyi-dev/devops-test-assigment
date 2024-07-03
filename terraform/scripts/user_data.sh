#!/bin/bash
# Update the package index
sudo apt-get update

# Install Apache
sudo apt-get install -y apache2

# Start Apache service
sudo systemctl start apache2

# Enable Apache service to start on boot
sudo systemctl enable apache2

# Install MySQL client
sudo apt-get install -y mysql-client

# Download and install WordPress
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo rsync -av wordpress/* /var/www/html/

# Set the correct permissions
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
