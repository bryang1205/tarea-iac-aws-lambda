resource "aws_iam_role" "upload_lambda" {
  name        = "${var.project}-${var.env}-upload-lambda-role"
  description = "Rol de ejecución para upload-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAssume"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project}-${var.env}-upload-lambda-role"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_iam_role_policy_attachment" "upload_basic_execution" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "upload_vpc_access" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_role_policy" "upload_s3" {
  name = "${var.project}-${var.env}-upload-lambda-s3-policy"
  role = aws_iam_role.upload_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPutObjectUploads"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.project}-${var.env}-images/uploads/*"
      }
    ]
  })
}


resource "aws_iam_role" "crop_lambda" {
  name        = "${var.project}-${var.env}-crop-lambda-role"
  description = "Rol de ejecución para crop-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAssume"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project}-${var.env}-crop-lambda-role"
    Project = var.project
    Env     = var.env
  }
}


resource "aws_iam_role_policy_attachment" "crop_basic_execution" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc_access" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_role_policy" "crop_s3" {
  name = "${var.project}-${var.env}-crop-lambda-s3-policy"
  role = aws_iam_role.crop_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowGetObjectUploads"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.project}-${var.env}-images/uploads/*"
      },
      {
        Sid      = "AllowPutObjectProcessed"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.project}-${var.env}-images/processed/*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "crop_sqs" {
  name = "${var.project}-${var.env}-crop-lambda-sqs-policy"
  role = aws_iam_role.crop_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSOperations"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}