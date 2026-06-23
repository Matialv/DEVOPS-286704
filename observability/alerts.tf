# Las alarmas CloudWatch están implementadas en infrastructure/modules/observability/main.tf
# y se despliegan via module "observability" en cada environment (dev/test/prod).
#
# Alarmas implementadas:
#   1. alb_5xx_errors      — 5xx errors > 10 en 5 min  → SNS email
#   2. ecs_cpu_high        — CPU > 80% por 10 min (por servicio) → SNS email
#   3. alb_latency_high    — Latencia p99 > 2s → SNS email
#   4. unhealthy_hosts     — Hosts unhealthy > 0 → SNS email
#
# Las alertas de vulnerabilidades ECR están en infrastructure/modules/lambda/
# (Lambda + EventBridge + SNS).
