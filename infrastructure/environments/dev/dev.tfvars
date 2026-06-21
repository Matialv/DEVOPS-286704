environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
image_tag          = "dev-77845a1a6462303cf6aefd154b8d6c06ef297de7"
# Actualizar image_tag después de que deploy.yml complete: dev-<git-sha>
# sns_email se pasa desde variable de entorno o GitHub Secret
