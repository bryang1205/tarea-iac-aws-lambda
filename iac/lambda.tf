data "archive_file" "upload_lambda" {
  type        = "zip"
  source_dir  = "../src/upload"
  output_path = "../src/upload.zip"
}

data "archive_file" "crop_lambda" {
  type        = "zip"
  source_dir  = "../src/crop"
  output_path = "../src/crop.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "${var.project}-${var.env}-upload"
  description      = "Recibe imágenes via API Gateway y las sube a S3 en uploads/"
  role             = aws_iam_role.upload_lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  memory_size      = var.upload_lambda_memory  # 256 MB (según diagrama)
  timeout          = var.upload_lambda_timeout  # 30s   (según diagrama)

  filename         = data.archive_file.upload_lambda.output_path
  source_code_hash = data.archive_file.upload_lambda.output_base64sha256

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.bucket
      UPLOAD_PREFIX = "uploads/"
    }
  }


  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.upload_basic_execution,
    aws_iam_role_policy_attachment.upload_vpc_access,
    aws_cloudwatch_log_group.upload_lambda
  ]

  tags = {
    Name    = "${var.project}-${var.env}-upload"
    Project = var.project
    Env     = var.env
  }
}




resource "aws_lambda_function" "crop" {
  function_name    = "${var.project}-${var.env}-crop"
  description      = "Consume mensajes SQS, descarga imagen de S3, recorta a 40x40 PNG circular y guarda en processed/"
  role             = aws_iam_role.crop_lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  memory_size      = var.crop_lambda_memory  # 512 MB (según diagrama)
  timeout          = var.crop_lambda_timeout  # 60s   (según diagrama)

  filename         = data.archive_file.crop_lambda.output_path
  source_code_hash = data.archive_file.crop_lambda.output_base64sha256

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.bucket
      PROCESSED_PREFIX = "processed/"
    }
  }


  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.crop_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.crop_basic_execution,
    aws_iam_role_policy_attachment.crop_vpc_access,
    aws_cloudwatch_log_group.crop_lambda
  ]

  tags = {
    Name    = "${var.project}-${var.env}-crop"
    Project = var.project
    Env     = var.env
  }
}


resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn                   = aws_sqs_queue.main.arn
  function_name                      = aws_lambda_function.crop.arn
  batch_size                         = 5
  enabled                            = true

  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [aws_iam_role_policy.crop_sqs]
}
