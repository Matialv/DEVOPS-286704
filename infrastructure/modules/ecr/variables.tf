variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "services" {
  description = "Lista de microservicios para los que se crean repositorios ECR"
  type        = list(string)
  default     = ["catalog", "cart", "checkout", "orders", "ui", "admin"]
}

variable "max_images" {
  description = "Cantidad máxima de imágenes a conservar por repositorio"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos para control de costos"
  type        = map(string)
  default     = {}
}
