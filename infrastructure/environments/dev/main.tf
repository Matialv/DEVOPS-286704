terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "retailstore-dev-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags { tags = local.common_tags }
}

locals {
  common_tags = {
    Project     = "RetailStore"
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = "RetailStore-${var.environment}"
  }
}

module "networking" {
  source      = "../../modules/networking"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  tags        = local.common_tags
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
  tags        = local.common_tags
}

module "rds" {
  source             = "../../modules/rds"
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  sg_rds_id          = module.networking.sg_rds_id
  instance_class     = var.rds_instance_class
  multi_az           = var.multi_az
  tags               = local.common_tags
}

module "elasticache" {
  source             = "../../modules/elasticache"
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  sg_redis_id        = module.networking.sg_redis_id
  node_type          = var.redis_node_type
  tags               = local.common_tags
}

module "ecs" {
  source               = "../../modules/ecs"
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  sg_alb_id            = module.networking.sg_alb_id
  sg_ecs_id            = module.networking.sg_ecs_id
  ecr_repository_urls  = module.ecr.repository_urls
  image_tag            = var.image_tag
  desired_count        = var.ecs_desired_count
  db_secret_arn        = module.rds.db_secret_arn
  redis_endpoint       = "${module.elasticache.redis_endpoint}:${module.elasticache.redis_port}"
  tags                 = local.common_tags
}

module "lambda" {
  source      = "../../modules/lambda"
  environment = var.environment
  sns_email   = var.sns_email
  tags        = local.common_tags
}
