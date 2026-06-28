environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
redis_node_type    = "cache.t3.micro"
sns_email          = "matialv15@gmail.com"
image_tag          = "dev-b9367f902cf83e5c7ac564a1a5392c5c273b81ca"
