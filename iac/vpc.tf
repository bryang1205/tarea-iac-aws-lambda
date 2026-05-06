resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private[*].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3BucketAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.project}-${var.env}-images/*"
      }
    ]
  })

  tags = {
    Name    = "${var.project}-${var.env}-vpce-s3"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.vpce_sqs_single_az ? [aws_subnet.private[0].id] : aws_subnet.private[*].id

  security_group_ids = [aws_security_group.vpce_sqs.id]

  tags = {
    Name    = "${var.project}-${var.env}-vpce-sqs"
    Project = var.project
    Env     = var.env
  }
}