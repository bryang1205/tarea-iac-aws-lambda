# VPC

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames  = true

  tags = {
    Name    = "${var.project}-${local.env}-vpc"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-${local.env}-igw"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project}-${local.env}-public-${var.availability_zones[count.index]}"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project}-${local.env}-private-${var.availability_zones[count.index]}"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway_ha ? length(var.availability_zones) : 1
  domain = "vpc"

  tags = {
    Name    = "${var.project}-${local.env}-eip-nat-${count.index}"
    Project = var.project
    Env     = local.env
  }
}



resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway_ha ? length(var.availability_zones) : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name    = "${var.project}-${local.env}-nat-${count.index}"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project}-${local.env}-rt-public"
    Project = var.project
    Env     = local.env
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway_ha ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
  }

  tags = {
    Name    = "${var.project}-${local.env}-rt-private-${count.index}"
    Project = var.project
    Env     = local.env
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "upload_lambda" {
  name        = "${var.project}-${local.env}-sg-upload-lambda"
  description = "SG para upload-lambda: sin inbound, outbound 443 a VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS hacia VPC Endpoints de S3 y SQS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${local.env}-sg-upload-lambda"
    Project = var.project
    Env     = local.env
  }
}


resource "aws_security_group" "crop_lambda" {
  name        = "${var.project}-${local.env}-sg-crop-lambda"
  description = "SG para crop-lambda: sin inbound, outbound 443 a VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS hacia VPC Endpoints de S3 y SQS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${local.env}-sg-crop-lambda"
    Project = var.project
    Env     = local.env
  }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "${var.project}-${local.env}-sg-vpce-sqs"
  description = "SG para el VPC Endpoint de SQS: inbound 443 desde lambdas"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS desde upload-lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.upload_lambda.id]
  }

  ingress {
    description     = "HTTPS desde crop-lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.crop_lambda.id]
  }

  tags = {
    Name    = "${var.project}-${local.env}-sg-vpce-sqs"
    Project = var.project
    Env     = local.env
  }
}