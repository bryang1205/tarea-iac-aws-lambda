resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project}-${var.env}-image-dlq"
  message_retention_seconds = 1209600 # 14 días (según diagrama)

  tags = {
    Name    = "${var.project}-${local.env}-image-dlq"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_sqs_queue" "main" {
  name                       = "${var.project}-${local.env}-image-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout 
  message_retention_seconds  = 86400                      
  receive_wait_time_seconds  = 20                          

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count 
  })

  tags = {
    Name    = "${var.project}-${local.env}-image-queue"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Notifications"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::${var.project}-${var.env}-images"
          }
        }
      }
    ]
  })
}
