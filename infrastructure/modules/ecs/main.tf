data "aws_iam_role" "labrole" {
  name = "LabRole"
}

locals {
  services = ["catalog", "cart", "checkout", "orders", "ui", "admin"]

  service_ports = {
    catalog  = 8001
    cart     = 8002
    checkout = 8003
    orders   = 8004
    ui       = 3000
    admin    = 3001
  }
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
    image     = "${var.ecr_repository_urls[each.key]}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = local.service_ports[each.key]
      protocol      = "tcp"
    }]

    secrets = [{
      name      = "DATABASE_URL"
      valueFrom = var.db_secret_arn
    }]

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
  port        = local.service_ports[each.key]
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
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

# ─── Additional listeners per service (puerto interno = puerto externo en ALB) ───
resource "aws_lb_listener" "service_ports" {
  for_each = {
    catalog  = 8001
    cart     = 8002
    checkout = 8003
    orders   = 8004
    admin    = 3001
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
    container_port   = local.service_ports[each.key]
  }

  depends_on = [aws_lb_listener.http]

  tags = merge(var.tags, {
    Name    = "retailstore-${var.environment}-${each.key}"
    Service = each.key
  })
}
