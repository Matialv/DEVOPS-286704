# ADR 002: Orquestación de contenedores - ECS Fargate

## Estado
Aceptado

## Contexto
Se necesita elegir el servicio de orquestación para los 6 microservicios en AWS.

## Decisión
Se usa **Amazon ECS con Fargate**.

## Justificación
- Serverless: sin nodos EC2 que parchear o escalar manualmente
- El repositorio de ejemplo (cicd-ecs) ya usa ECS como referencia
- Menor complejidad operativa vs EKS para este tamaño de proyecto
- Integración nativa con ECR, CloudWatch, ALB y Secrets Manager

## Consecuencias
- No se gestiona infraestructura de nodos
- Se paga por vCPU y memoria por tarea (cost-effective a esta escala)
