#!/bin/bash
# Script one-time: crea la tabla DynamoDB para el lock de estado de Terraform
# Los buckets S3 "retailstore-{dev|test|prod}-terraform-state" ya existen y fueron creados manualmente
# Ejecutar UNA SOLA VEZ antes del primer terraform init
#

set -e

REGION="us-east-1"
TABLE="terraform-lock"

echo "Creando tabla DynamoDB: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "Bootstrap completado. Ahora podés ejecutar: terraform init"
