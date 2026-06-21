environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.micro"
multi_az           = false
image_tag          = "dev-a44a5d40e8c2ffbed33dc88aade8bfd16e159205"
# Actualizar image_tag después de que deploy.yml complete: dev-<git-sha>
# sns_email se pasa desde variable de entorno o GitHub Secret
