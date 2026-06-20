variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos para control de costos"
  type        = map(string)
  default     = {}
}
