variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "image_tag" {
  description = "Tag de imagen a desplegar (formato: <ambiente>-<sha>)"
  type        = string
}

variable "sns_email" {
  description = "Email para alertas de seguridad"
  type        = string
}
