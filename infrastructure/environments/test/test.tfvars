environment        = "test"
vpc_cidr           = "10.1.0.0/16"
ecs_desired_count  = 1
rds_instance_class = "db.t3.small"
multi_az           = false
image_tag          = "test-initial"
# Actualizar image_tag después de que deploy.yml complete: test-<git-sha>
# sns_email se pasa desde variable de entorno o GitHub Secret
