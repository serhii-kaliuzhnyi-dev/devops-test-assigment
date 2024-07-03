variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "db_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "rds_port" {
  description = "The port on which the DB accepts connections"
  type        = string
  default     = "3306"
}

variable "public_key_path" {
  description = "Path to the public key file to be used for the EC2 instance"
  type        = string
}