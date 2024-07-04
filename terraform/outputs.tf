output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "ec2_instance_ip" {
  value = module.ec2_instance.public_ip
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "elasticache_endpoint" {
  value = module.elasticache.replication_group_primary_endpoint_address
}
