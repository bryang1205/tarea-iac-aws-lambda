variable "aws_region" {
  description = "Región de AWS "
  type        = string
  default     = "us-east-2"
}

variable "env" {
  description = "entorno"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Proyecto"
  type        = string
  default     = "image-processor"
}

variable "vpc_cidr" {
  description = "VPC CIRD"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "subnets privadas"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "AZs a utilizar"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "enable_nat_gateway_ha" {
  description = "NAT Gateway."
  type        = bool
  default     = false
}

variable "vpce_sqs_single_az" {
  description = "Si true, despliega el VPC Endpoint de SQS en una sola AZ para reducir costos"
  type        = bool
  default     = true
}


variable "uploads_expiration_days" {
  description = "Días antes de expirar objetos en uploads/"
  type        = number
  default     = 30
}

variable "processed_expiration_days" {
  description = "Días antes de expirar objetos en processed/"
  type        = number
  default     = 90
}

variable "sqs_visibility_timeout" {
  description = "Visibility timeout de la cola"
  type        = number
  default     = 360
}

variable "sqs_max_receive_count" {
  description = "Intentos antes de enviar mensaje al DLQ"
  type        = number
  default     = 3
}


variable "upload_lambda_memory" {
  description = "Memoria asignada a upload-lambda (MB)"
  type        = number
  default     = 256
}

variable "upload_lambda_timeout" {
  description = "Timeout de upload-lambda (segundos)"
  type        = number
  default     = 30
}

variable "crop_lambda_memory" {
  description = "Memoria asignada a crop-lambda (MB)"
  type        = number
  default     = 512
}

variable "crop_lambda_timeout" {
  description = "Timeout de crop-lambda (segundos)"
  type        = number
  default     = 60
}