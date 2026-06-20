#!/bin/bash
# Script one-time: crea el bucket S3 y tabla DynamoDB para el estado remoto de Terraform
# Ejecutar UNA SOLA VEZ antes del primer terraform init

set -e

REGION="us-east-1"
BUCKET="retailstore-286704-terraform-state"
TABLE="terraform-lock"

echo "Creando bucket S3: $BUCKET"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

echo "Creando tabla DynamoDB: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "Bootstrap completado. Ahora podés ejecutar: terraform init"
