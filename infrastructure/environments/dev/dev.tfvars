environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
# image_tag se pasa desde el pipeline: dev-<git-sha>
# sns_email se pasa desde variable de entorno o GitHub Secret
