variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del SNS Topic para alertas"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix del ALB para métricas CloudWatch"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}
