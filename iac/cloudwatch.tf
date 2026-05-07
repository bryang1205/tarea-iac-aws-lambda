# ── LOG GROUP — API GATEWAY ───────────────────────────────────────────────────
# El diagrama indica: formato JSON, retención 14 días

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${var.project}-${local.env}"
  retention_in_days = 14

  tags = {
    Name    = "/aws/apigateway/${var.project}-${local.env}"
    Project = var.project
    Env     = local.env
  }
}

# ── LOG GROUP — UPLOAD LAMBDA ─────────────────────────────────────────────────
# El diagrama indica: /aws/lambda/...-upload, retención 14 días

resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${var.project}-${local.env}-upload"
  retention_in_days = 14

  tags = {
    Name    = "/aws/lambda/${var.project}-${local.env}-upload"
    Project = var.project
    Env     = local.env
  }
}

# ── LOG GROUP — CROP LAMBDA ───────────────────────────────────────────────────
# El diagrama indica: /aws/lambda/...-crop, retención 14 días

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${var.project}-${local.env}-crop"
  retention_in_days = 14

  tags = {
    Name    = "/aws/lambda/${var.project}-${local.env}-crop"
    Project = var.project
    Env     = local.env
  }
}

# ── SNS TOPIC PARA LA ALARMA ──────────────────────────────────────────────────
# El diagrama indica: Action notify via SNS topic

resource "aws_sns_topic" "dlq_alarm" {
  name = "${var.project}-${local.env}-dlq-alarm-topic"

  tags = {
    Name    = "${var.project}-${local.env}-dlq-alarm-topic"
    Project = var.project
    Env     = local.env
  }
}

# ── CLOUDWATCH ALARM — DLQ ────────────────────────────────────────────────────
# El diagrama indica:
#   Metric: ApproximateNumberOfMessagesVisible
#   Namespace: AWS/SQS
#   Period: 60s
#   Threshold: above 0 → cualquier mensaje dispara la alarma
#   Action: notify via SNS topic

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project}-${local.env}-dlq-messages-alarm"
  alarm_description   = "Alerta cuando el DLQ tiene mensajes visibles — indica fallos en crop-lambda"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm.arn]

  tags = {
    Name    = "${var.project}-${local.env}-dlq-messages-alarm"
    Project = var.project
    Env     = local.env
  }
}