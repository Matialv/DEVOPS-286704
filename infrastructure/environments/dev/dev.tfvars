environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
image_tag          = "dev-92e2db18e13e00c940e040eed0d39fba4383d37a" "dev-initial"
# Actualizar image_tag después de que deploy.yml complete: dev-<git-sha>
# sns_email se pasa desde variable de entorno o GitHub Secret
