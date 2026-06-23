data "aws_iam_role" "labrole" {
  name = "LabRole"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_secret_arn
}

locals {
  services = ["catalog", "cart", "checkout", "orders", "ui", "admin"]

  # Puertos internos donde escuchan los containers
  service_internal_ports = {
    catalog  = 8080
    cart     = 8080
    checkout = 3000
    orders   = 8080
    ui       = 8080
    admin    = 3000
  }

  # Puertos externos en el ALB
  service_alb_ports = {
    catalog  = 8001
    cart     = 8002
    checkout = 8003
    orders   = 8004
    ui       = 80
    admin    = 3001
  }
}

# ─── Data source: ECR repositories (creados por deploy.yml) ────────────────────

data "aws_ecr_repository" "services" {
  for_each = toset(local.services)
  name     = "retailstore-${each.key}"
}


# ─── ECS Cluster ─────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "retailstore-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-cluster" })
}

# ─── CloudWatch Log Groups por servicio ──────────────────────────────────────

resource "aws_cloudwatch_log_group" "services" {
  for_each = toset(local.services)

  name              = "/retailstore/${var.environment}/${each.key}"
  retention_in_days = var.environment == "prod" ? 90 : 30

  tags = merge(var.tags, {
    Name    = "/retailstore/${var.environment}/${each.key}"
    Service = each.key
  })
}

# ─── Task Definitions ────────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "services" {
  for_each = toset(local.services)

  family                   = "retailstore-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = data.aws_iam_role.labrole.arn
  task_role_arn            = data.aws_iam_role.labrole.arn

  container_definitions = jsonencode([{
    name      = each.key
    image     = "${data.aws_ecr_repository.services[each.key].repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = local.service_internal_ports[each.key]
      protocol      = "tcp"
    }]

    environment = concat(
      [
        {
          name  = "REDIS_URL"
          value = "redis://${var.redis_endpoint}"
        }
      ],
      each.key == "catalog" ? [
        {
          name  = "RETAIL_CATALOG_PERSISTENCE_PROVIDER"
          value = "postgres"
        },
        {
          name  = "RETAIL_CATALOG_PERSISTENCE_ENDPOINT"
          value = "${jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).host}:5432"
        },
        {
          name  = "RETAIL_CATALOG_PERSISTENCE_DB_NAME"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).dbname
        },
        {
          name  = "RETAIL_CATALOG_PERSISTENCE_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).username
        },
        {
          name  = "RETAIL_CATALOG_PERSISTENCE_CONNECT_TIMEOUT"
          value = "5"
        }
      ] : [],
      each.key == "orders" ? [
        {
          name  = "RETAIL_ORDERS_PERSISTENCE_ENDPOINT"
          value = "${jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).host}:5432"
        },
        {
          name  = "RETAIL_ORDERS_PERSISTENCE_USERNAME"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).username
        },
        {
          name  = "RETAIL_ORDERS_PERSISTENCE_NAME"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).dbname
        }
      ] : [],
      each.key == "cart" ? [
        {
          name  = "CART_PERSISTENCE_PROVIDER"
          value = "postgres"
        },
        {
          name  = "CART_POSTGRES_HOST"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).host
        },
        {
          name  = "CART_POSTGRES_PORT"
          value = "5432"
        },
        {
          name  = "CART_POSTGRES_DB"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).dbname
        },
        {
          name  = "CART_POSTGRES_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string).username
        }
      ] : [],
      each.key == "ui" ? [
        {
          name  = "RETAIL_UI_ENDPOINTS_CATALOG"
          value = "http://${aws_lb.main.dns_name}:8001"
        },
        {
          name  = "RETAIL_UI_ENDPOINTS_CARTS"
          value = "http://${aws_lb.main.dns_name}:8002"
        },
        {
          name  = "RETAIL_UI_ENDPOINTS_CHECKOUT"
          value = "http://${aws_lb.main.dns_name}:8003"
        },
        {
          name  = "RETAIL_UI_ENDPOINTS_ORDERS"
          value = "http://${aws_lb.main.dns_name}:8004"
        }
      ] : []
    )

    secrets = concat(
      [
        {
          name      = "DATABASE_URL"
          valueFrom = var.db_secret_arn
        }
      ],
      each.key == "catalog" ? [
        {
          name      = "RETAIL_CATALOG_PERSISTENCE_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ] : [],
      each.key == "orders" ? [
        {
          name      = "RETAIL_ORDERS_PERSISTENCE_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ] : [],
      each.key == "cart" ? [
        {
          name      = "CART_POSTGRES_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/retailstore/${var.environment}/${each.key}"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = each.key
      }
    }
  }])

  tags = merge(var.tags, {
    Name    = "retailstore-${var.environment}-${each.key}"
    Service = each.key
  })
}

# ─── ALB ─────────────────────────────────────────────────────────────────────
# test
resource "aws_lb" "main" {
  name               = "retailstore-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-alb" })
}

resource "aws_lb_target_group" "services" {
  for_each = toset(local.services)

  name        = "rs-${var.environment}-${each.key}"
  port        = local.service_internal_ports[each.key]
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name    = "rs-${var.environment}-${each.key}"
    Service = each.key
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["ui"].arn
  }
}

# ─── Additional listeners per service (puertos externos en el ALB) ───
resource "aws_lb_listener" "service_ports" {
  for_each = {
    catalog  = local.service_alb_ports["catalog"]
    cart     = local.service_alb_ports["cart"]
    checkout = local.service_alb_ports["checkout"]
    orders   = local.service_alb_ports["orders"]
    admin    = local.service_alb_ports["admin"]
  }

  load_balancer_arn = aws_lb.main.arn
  port              = each.value
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }
}

# ─── ECS Services ────────────────────────────────────────────────────────────

resource "aws_ecs_service" "services" {
  for_each = toset(local.services)

  name            = "retailstore-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.sg_ecs_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.services[each.key].arn
    container_name   = each.key
    container_port   = local.service_internal_ports[each.key]
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.service_ports
  ]

  tags = merge(var.tags, {
    Name    = "retailstore-${var.environment}-${each.key}"
    Service = each.key
  })
}
