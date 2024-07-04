provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "wordpress"
  region = var.aws_region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-rds"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key_path)
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name                            = local.name
  cidr                            = local.vpc_cidr
  azs                             = local.azs
  public_subnets                  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets                 = ["10.0.3.0/24", "10.0.4.0/24"]
  database_subnets                = ["10.0.5.0/24", "10.0.6.0/24"]
  elasticache_subnets             = ["10.0.7.0/24", "10.0.8.0/24"]
  enable_nat_gateway              = true
  single_nat_gateway              = true
  enable_dns_hostnames            = true
  enable_dns_support              = true
  create_database_subnet_group    = true
  create_elasticache_subnet_group = true
  create_igw                      = true

  tags = local.tags
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "${local.name}-ec2-sg"
  description = "Security group for EC2 instances in ${local.name} VPC"
  vpc_id      = module.vpc.vpc_id

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

  tags = {
    Name = "${local.name}-ec2-sg"
  }
}

# EC2 Instance
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name                         = local.name
  ami                          = "ami-04e48bc4c1f6bd229"
  instance_type                = "t2.micro"
  subnet_id                    = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids       = [aws_security_group.ec2.id]
  associate_public_ip_address  = true
  key_name                     = aws_key_pair.deployer.key_name
  user_data                    = templatefile("${path.module}/scripts/user_data.sh.tpl", {
    db_endpoint        = split(":", module.rds.db_instance_endpoint)[0],
    db_name            = module.rds.db_instance_name,
    db_username        = var.db_username,
    db_password        = var.db_password,
    redis_endpoint     = module.elasticache.replication_group_primary_endpoint_address
    redis_password     = var.auth_token
  })
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Security group for RDS in ${local.name} VPC"
  vpc_id      = module.vpc.vpc_id

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

  tags = {
    Name = "${local.name}-rds-sg"
  }
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache" {
  name        = "${local.name}-redis-sg"
  description = "Security group for ElastiCache in ${local.name} VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-redis-sg"
  }
}

# RDS MySQL Instance
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.7.0"

  identifier             = "${local.name}-db"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "wordpress"
  username               = var.db_username
  password               = var.db_password
  port                   = var.rds_port
  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.database_subnets
  major_engine_version   = "5.7"
  family                 = "mysql5.7"
  create_db_subnet_group = true
  manage_master_user_password = false

  tags = local.tags
}

# ElastiCache Redis
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.2.0"

  engine                      = "redis"
  engine_version              = "6.x"
  node_type                   = "cache.t2.micro"
  num_cache_nodes             = 1
  automatic_failover_enabled  = false
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  replication_group_id        = "${local.name}-redis"
  subnet_ids                  = module.vpc.elasticache_subnets
  security_group_ids          = [aws_security_group.elasticache.id]
  create_security_group       = false
  create_subnet_group         = true
  # auth_token                  = var.auth_token

  tags = local.tags
}
