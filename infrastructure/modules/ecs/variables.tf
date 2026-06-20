variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de subnets públicas para el ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs de subnets privadas para las tareas ECS"
  type        = list(string)
}

variable "sg_alb_id" {
  description = "Security Group del ALB"
  type        = string
}

variable "sg_ecs_id" {
  description = "Security Group de las tareas ECS"
  type        = string
}

variable "ecr_repository_urls" {
  description = "URLs de los repositorios ECR por servicio"
  type        = map(string)
}

variable "image_tag" {
  description = "Tag de imagen a desplegar (formato: <ambiente>-<sha>)"
  type        = string
}

variable "desired_count" {
  description = "Número de tareas ECS deseadas por servicio"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "CPU asignada a cada tarea ECS (unidades)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria asignada a cada tarea ECS (MB)"
  type        = number
  default     = 512
}

variable "db_secret_arn" {
  description = "ARN del secreto de RDS en Secrets Manager"
  type        = string
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos para control de costos"
  type        = map(string)
  default     = {}
}
