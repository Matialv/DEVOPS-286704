environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
redis_node_type    = "cache.t3.micro"
sns_email          = "matialv15@gmail.com"
image_tag          = "dev-fc802ce0184a621d1c8bbf53c9ee3ded65f84865"
