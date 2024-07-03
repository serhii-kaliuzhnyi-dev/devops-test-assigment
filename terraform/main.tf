provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key_path)
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name                              = "worpress-vpc"
  cidr                              = "10.0.0.0/16"
  azs                               = data.aws_availability_zones.available.names
  public_subnets                    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets                   = ["10.0.3.0/24", "10.0.4.0/24"]
  database_subnets                  = ["10.0.5.0/24", "10.0.6.0/24"]
  elasticache_subnets               = ["10.0.7.0/24", "10.0.8.0/24"]
  enable_nat_gateway                = true
  single_nat_gateway                = true
  enable_dns_hostnames              = true
  enable_dns_support                = true
  create_database_subnet_group      = true
  create_elasticache_subnet_group   = true
  create_igw                        = true

  tags = {
    Name = "worpress-vpc"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name                         = "wordpress"
  ami                          = "ami-0e872aee57663ae2d"
  instance_type                = "t2.micro"
  subnet_id                    = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids       = [module.vpc.default_security_group_id]
  associate_public_ip_address  = true
  key_name                     = aws_key_pair.deployer.key_name
  user_data                    = file("${path.module}/scripts/user_data.sh")
}

resource "aws_security_group" "rds" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS MySQL Instance
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.7.0"

  identifier             = "wordpress-db"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = "mysql"
  username               = var.db_username
  password               = var.db_password
  port                   = var.rds_port
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"
  create_db_subnet_group = true
  subnet_ids             = module.vpc.database_subnets
  create_monitoring_role = true
  major_engine_version   = "5.7"
  family                 = "mysql5.7"

  tags = {
    Name = "wordpress-db"
  }
}

# ElastiCache Redis
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.2.0"

  engine                = "redis"
  engine_version        = "6.x"
  node_type             = "cache.t2.micro"
  num_cache_nodes       = 1
  automatic_failover_enabled = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  create_replication_group = true
  replication_group_id = "wordpress-redis"

  subnet_ids             = module.vpc.private_subnets

  tags = {
    Name = "wordpress-redis"
  }
}