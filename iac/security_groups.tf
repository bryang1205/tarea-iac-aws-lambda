resource "aws_security_group" "upload_lambda" {
  name        = "${var.project}-${local.env}-sg-upload-lambda"
  description = "Grupo de seguridad para la funcion Lambda de carga"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-${local.env}-sg-upload-lambda"
    Project = var.project
    Env     = local.env
  }
}

resource "aws_security_group" "crop_lambda" {
  name        = "${var.project}-${local.env}-sg-crop-lambda"
  description = "Grupo de seguridad para la funcion Lambda de procesamiento"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-${local.env}-sg-crop-lambda"
    Project = var.project
    Env     = local.env
  }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "${var.project}-${local.env}-sg-vpce-sqs"
  description = "Grupo de seguridad para el VPC Endpoint Interface de Amazon SQS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-${local.env}-sg-vpce-sqs"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_vpc_security_group_egress_rule" "upload_lambda_https_out" {
  security_group_id = aws_security_group.upload_lambda.id
  description       = "Permitir salida HTTPS desde Lambda de carga hacia VPC Endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "crop_lambda_https_out" {
  security_group_id = aws_security_group.crop_lambda.id
  description       = "Permitir salida HTTPS desde Lambda de procesamiento hacia VPC Endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "vpce_sqs_https_out" {
  security_group_id = aws_security_group.vpce_sqs.id
  description       = "Permitir salida HTTPS desde endpoint SQS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}


resource "aws_vpc_security_group_ingress_rule" "vpce_sqs_from_upload_lambda" {
  security_group_id            = aws_security_group.vpce_sqs.id
  description                  = "Permitir HTTPS desde Lambda de carga hacia endpoint SQS"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.upload_lambda.id
}

resource "aws_vpc_security_group_ingress_rule" "vpce_sqs_from_crop_lambda" {
  security_group_id            = aws_security_group.vpce_sqs.id
  description                  = "Permitir HTTPS desde Lambda de procesamiento hacia endpoint SQS"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.crop_lambda.id
}