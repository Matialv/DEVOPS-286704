terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    key     = "ecr/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags { tags = var.tags }
}

# ─── Repositorios ECR por servicio ───────────────────────────────────────────

resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)

  name                 = "retailstore-${var.environment}-${each.key}"
  image_tag_mutability = "IMMUTABLE" # tag inmutable: no se puede sobreescribir un tag existente

  image_scanning_configuration {
    scan_on_push = true # escaneo automático al hacer push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name        = "retailstore-${var.environment}-${each.key}"
    Service     = each.key
    Environment = var.environment
  })
}

# ─── Lifecycle policy: conservar máximo N imágenes por repositorio ───────────

resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener solo las últimas ${var.max_images} imágenes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

