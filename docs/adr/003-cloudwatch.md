# ADR 003: Observabilidad - CloudWatch

## Estado
Aceptado

## Contexto
Se necesita una solución de monitoreo para métricas, logs y alertas.

## Decisión
Se usa **Amazon CloudWatch** como plataforma de observabilidad.

## Justificación
- Nativo de AWS: cero infraestructura adicional a desplegar
- Integración automática con ECS Fargate (métricas de CPU/Memoria sin configuración)
- Los microservicios cart y orders ya exponen métricas Prometheus (compatible con CloudWatch Agent)
- CloudWatch Alarms + SNS para notificaciones sin herramientas externas

## Consecuencias
- Dashboards menos flexibles que Grafana, pero suficientes para el alcance del proyecto
- Costo según volumen de logs y métricas personalizadas
