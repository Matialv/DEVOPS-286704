environment        = "prod"
vpc_cidr           = "10.2.0.0/16"
ecs_desired_count  = 2
rds_instance_class = "db.t3.medium"
multi_az           = true
redis_node_type    = "cache.t3.medium"
sns_email          = "matialv15@gmail.com"
image_tag          = "prod-dcb6a1a600d1933687e319e31690cedb0fa55786"
