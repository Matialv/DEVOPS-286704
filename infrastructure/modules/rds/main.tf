resource "random_password" "db" {
  length  = 32
  special = false
}

# ─── Secreto en Secrets Manager (nunca en texto plano) ───────────────────────

resource "aws_secretsmanager_secret" "db" {
  name        = "retailstore/${var.environment}/db-credentials"
  description = "Credenciales de RDS PostgreSQL para RetailStore ${var.environment}"
  tags        = merge(var.tags, { Name = "retailstore-${var.environment}-db-secret" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "retailstore"
    password = random_password.db.result
    dbname   = var.db_name
    host     = aws_db_instance.main.address
    port     = 5432
  })
}

# ─── Subnet Group ────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "retailstore-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "retailstore-${var.environment}-db-subnet" })
}

# ─── RDS PostgreSQL ──────────────────────────────────────────────────────────

resource "aws_db_instance" "main" {
  identifier        = "retailstore-${var.environment}-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_encrypted = true

  db_name  = var.db_name
  username = "retailstore"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.sg_rds_id]

  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.environment != "prod"
  deletion_protection    = var.environment == "prod"

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-db" })
}
