output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas (ALB)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas (ECS, RDS, Redis)"
  value       = aws_subnet.private[*].id
}

output "sg_alb_id" {
  description = "Security Group del ALB"
  value       = aws_security_group.alb.id
}

output "sg_ecs_id" {
  description = "Security Group de las tareas ECS"
  value       = aws_security_group.ecs.id
}

output "sg_rds_id" {
  description = "Security Group de RDS"
  value       = aws_security_group.rds.id
}

output "sg_redis_id" {
  description = "Security Group de Redis"
  value       = aws_security_group.redis.id
}
