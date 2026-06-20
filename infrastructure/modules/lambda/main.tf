data "aws_iam_role" "labrole" {
  name = "LabRole"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── SNS Topic para alertas ──────────────────────────────────────────────────

resource "aws_sns_topic" "security_alerts" {
  name = "retailstore-${var.environment}-security-alerts"
  tags = merge(var.tags, { Name = "retailstore-${var.environment}-security-alerts" })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

# ─── IAM Role para Lambda ────────────────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "retailstore-${var.environment}-ecr-scan-notifier"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = merge(var.tags, { Name = "retailstore-${var.environment}-ecr-scan-notifier" })
}

resource "aws_iam_role_policy" "lambda" {
  name = "retailstore-${var.environment}-ecr-scan-notifier-policy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# ─── Lambda Function ─────────────────────────────────────────────────────────

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/ecr_scan_notifier.py"
  output_path = "${path.module}/ecr_scan_notifier.zip"
}

resource "aws_lambda_function" "ecr_scan_notifier" {
  function_name    = "retailstore-${var.environment}-ecr-scan-notifier"
  role             = aws_iam_role.lambda.arn
  handler          = "ecr_scan_notifier.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      ENVIRONMENT   = var.environment
    }
  }

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-ecr-scan-notifier" })
}

# ─── EventBridge: trigger en ECR Scan Complete ───────────────────────────────

resource "aws_cloudwatch_event_rule" "ecr_scan" {
  name        = "retailstore-${var.environment}-ecr-scan-complete"
  description = "Dispara Lambda cuando ECR completa un escaneo de imagen"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Scan"]
    detail = {
      scan-status = ["COMPLETE"]
    }
  })

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-ecr-scan-rule" })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.ecr_scan.name
  target_id = "ecr-scan-notifier"
  arn       = aws_lambda_function.ecr_scan_notifier.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecr_scan_notifier.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_scan.arn
}
