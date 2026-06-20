variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "sns_email" {
  description = "Email para notificaciones de vulnerabilidades críticas"
  type        = string
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos para control de costos"
  type        = map(string)
  default     = {}
}
