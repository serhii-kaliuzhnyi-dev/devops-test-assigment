# Terraform WordPress Deployment with ElastiCache and RDS 🎉

## Overview 📚
This project sets up a WordPress site using AWS services including RDS for the database and ElastiCache for session management. The deployment script uses Terraform to provision the necessary infrastructure and configurations.

## Features 🌟
- Automated deployment of WordPress with RDS and ElastiCache
- Customizable configuration options
- Pre-configured Terraform hooks for formatting, validation
- Environment variable management for secure configurations

## Prerequisites 📋
- Terraform installed on your machine
- AWS account and necessary permissions
- SSH key pair for EC2 instance access

## Configuration Options ⚙️
### Terraform Variables
- `aws_region`: The AWS region to deploy resources.
- `db_username`: The master username for the RDS instance.
- `db_password`: The master password for the RDS instance.
- `rds_port`: The port to database
- `public_key_path`: Path to your public SSH key.
- `auth_token`: Password for the ElastiCache Redis instance.

### Environment Variables
- `DB_NAME`: Name of the WordPress database.
- `DB_USER`: Username for the WordPress database.
- `DB_PASSWORD`: Password for the WordPress database.
- `DB_HOST`: Hostname for the WordPress database.
- `CACHE_HOST`: Endpoint for the Redis cache.

## Deployment Steps 🚀
1. **Clone the repository**:
   ```sh
   git clone <repository_url>
   cd <repository_directory>


### 2. Configure Terraform Variables
Create a `terraform.tfvars` file and populate it with your configuration:
```hcl
aws_region = "eu-central-1"
db_username = "your_db_username"
db_password = "your_db_password"
rds_port    = "3306"
public_key_path = "~/.ssh/id_rsa.pub"
auth_token = "your_redis_super_secret_password"
```

#### 2.1 Generating an SSH Key Pair (If you don't have one) 🔑
1. **Generate the SSH Key Pair**:
   ```sh
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```
2. **Follow the prompts:**
Save the file in the default location (press Enter).
Enter a passphrase (optional, but recommended).

3. **Add your SSH key to the SSH agent:**
    ```sh
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    ```

### 3. Initialize Terraform
```sh
terraform init
```

### 4. (Optional) Review the Terraform Plan
```sh
terraform plan
```

### 5. Apply the Terraform Configuration
```sh
terraform apply
```

### 6. Access Your WordPress Site
Retrieve the public IP of your EC2 instance from the Terraform output and visit it in your browser.


## Troubleshooting Tips 🔧
- Ensure the Redis extension is properly installed and configured in `php.ini`. You can configure WordPress sessions with ElastiCache Redis by following these steps:

  ```sh
  # Install PECL and Redis PECL extension
  sudo apt-get install -y php-pear php-dev
  sudo pecl install redis

  # Enable Redis extension in PHP
  sudo bash -c 'echo "extension=redis.so" >> /opt/bitnami/php/etc/php.ini'

  # Replace existing session.save_handler and session.save_path in PHP
  sudo sed -i "s|session.save_handler = .*|session.save_handler = redis|" /opt/bitnami/php/etc/php.ini
  sudo sed -i "s|session.save_path = .*|session.save_path = \"tls://${redis_endpoint}:6379\"|" /opt/bitnami/php/etc/php.ini

- **Error: `Access denied for user 'username'@'hostname'`**:
  Verify that the RDS instance is properly configured with the correct username and password.

- **ElastiCache connectivity issues**:
  Check security group settings to ensure the EC2 instance can communicate with the ElastiCache instance.

## Getting the initial admin user credentials on Bitnami AMI
 For Bitnami AMIs, you can obtain the initial admin user credentials by checking the system log of your EC2 instance. The credentials are displayed during the first boot.
 ```sh
 # Steps to retrieve the admin credentials
1. Open the Amazon EC2 console.
2. Select the instance running WordPress.
3. Click on the "Actions" button and select "Instance Settings" > "Get System Log".
4. Look for the message that contains the application username and password.
```

## External Terraform Modules and Deployment Tools 📦

I decided to use Terraform modules for RDS, ElastiCache, EC2, and VPC for several reasons:

- **Learning Experience**: I had a lack of experience with these modules and wanted to practice using them to gain proficiency.
- **Efficiency**: These modules streamline the deployment process, allowing for faster and more consistent infrastructure provisioning.
- **Popularity**: The chosen modules are widely used and trusted within the Terraform community, ensuring reliability and support.
- **Maintenance**: The modules are maintained by Terraform expert Anton Babenko, providing assurance of quality and regular updates.

The specific modules used in this project are:
- **VPC Module**: For creating and managing the VPC and related networking resources.
- **EC2 Module**: For provisioning EC2 instances with necessary configurations.
- **RDS Module**: For deploying and managing the RDS instance.
- **ElastiCache Module**: For setting up ElastiCache with Redis engine.

Using these modules has enabled a more streamlined and efficient infrastructure setup, leveraging best practices and community expertise.


## Project Structure 📁

The project directory is organized as follows:

- **terraform/**
  - **.terraform/**: Directory containing Terraform's internal files.
  - **scripts/**: Directory for scripts used in Terraform provisioning.
    - **user_data.sh.tpl**: Template file for user data script used to configure EC2 instances.
  - **main.tf**: Main Terraform configuration file containing the resource definitions.
  - **outputs.tf**: File defining the outputs of the Terraform configuration.
  - **variables.tf**: File defining the input variables for the Terraform configuration.

Each directory and file serves a specific purpose to ensure a modular, maintainable, and efficient infrastructure setup using Terraform.
