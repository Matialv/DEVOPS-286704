environment        = "prod"
vpc_cidr           = "10.2.0.0/16"
ecs_desired_count  = 2
rds_instance_class = "db.t3.medium"
multi_az           = true
# image_tag se pasa desde el pipeline: prod-<git-sha>
# sns_email se pasa desde variable de entorno o GitHub Secret
