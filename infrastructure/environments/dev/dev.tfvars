environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
redis_node_type    = "cache.t3.micro"
sns_email          = "matialv15@gmail.com"
image_tag          = "dev-1f2ed331b57460e0479f103e9b17cda10ab2f2fb"
