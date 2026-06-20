# Estado remoto en S3 + locking con DynamoDB
# Ejecutar bootstrap/ antes de hacer terraform init
data "aws_iam_role" "labrole" {
  name = "LabRole"
}
terraform {
  
  backend "s3" {
    bucket         = "retailstore-286704-terraform-state"
    key            = "retailstore/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
