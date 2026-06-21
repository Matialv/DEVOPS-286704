variable "environment" {
  type    = string
  default = "test"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.small"
}

variable "image_tag" {
  description = "Tag de imagen a desplegar (formato: <ambiente>-<sha>)"
  type        = string
}

variable "sns_email" {
  type        = string
  description = "Email para alertas de seguridad"
}
