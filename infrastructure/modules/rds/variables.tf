variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de subnets privadas donde se despliega RDS"
  type        = list(string)
}

variable "sg_rds_id" {
  description = "Security Group de RDS"
  type        = string
}

variable "instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Habilitar Multi-AZ para alta disponibilidad"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "retailstore"
}

variable "tags" {
  description = "Tags a aplicar a todos los recursos para control de costos"
  type        = map(string)
  default     = {}
}
