environment        = "prod"
vpc_cidr           = "10.2.0.0/16"
ecs_desired_count  = 2
rds_instance_class = "db.t3.medium"
multi_az           = true
redis_node_type    = "cache.t3.medium"
sns_email          = "matialv15@gmail.com"
image_tag          = "prod-45e4a916fd52b3979437b2b8cb53f077b9b761e0"
