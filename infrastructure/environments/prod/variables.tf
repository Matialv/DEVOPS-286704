variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "image_tag" {
  description = "Tag de imagen a desplegar (formato: <ambiente>-<sha>)"
  type        = string
}

variable "sns_email" {
  type        = string
  description = "Email para alertas de seguridad"
}
