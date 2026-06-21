variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de subnets privadas donde se despliega Redis"
  type        = list(string)
}

variable "sg_redis_id" {
  description = "Security Group de Redis"
  type        = string
}

variable "node_type" {
  description = "Tipo de nodo Redis"
  type        = string
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos para control de costos"
  type        = map(string)
  default     = {}
}
