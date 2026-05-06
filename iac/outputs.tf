output "api_endpoint" {
  description = "URL base del API Gateway para hacer POST /upload"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_upload_url" {
  description = "URL completa para subir imágenes"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/upload"
}


output "s3_bucket_name" {
  description = "Nombre del bucket S3 de imágenes"
  value       = aws_s3_bucket.images.bucket
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3 de imágenes"
  value       = aws_s3_bucket.images.arn
}


output "sqs_queue_url" {
  description = "URL de la cola principal SQS"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "ARN de la cola principal SQS"
  value       = aws_sqs_queue.main.arn
}

output "sqs_dlq_url" {
  description = "URL del Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.url
}

output "sqs_dlq_arn" {
  description = "ARN del Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.arn
}

output "upload_lambda_name" {
  description = "Nombre de la upload-lambda"
  value       = aws_lambda_function.upload.function_name
}

output "upload_lambda_arn" {
  description = "ARN de la upload-lambda"
  value       = aws_lambda_function.upload.arn
}

output "crop_lambda_name" {
  description = "Nombre de la crop-lambda"
  value       = aws_lambda_function.crop.function_name
}

output "crop_lambda_arn" {
  description = "ARN de la crop-lambda"
  value       = aws_lambda_function.crop.arn
}

output "vpc_id" {
  description = "ID del VPC principal"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas donde corren las Lambdas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas donde está el NAT Gateway"
  value       = aws_subnet.public[*].id
}

output "vpce_s3_id" {
  description = "ID del VPC Endpoint Gateway para S3"
  value       = aws_vpc_endpoint.s3.id
}

output "vpce_sqs_id" {
  description = "ID del VPC Endpoint Interface para SQS"
  value       = aws_vpc_endpoint.sqs.id
}

output "upload_lambda_role_arn" {
  description = "ARN del rol IAM de upload-lambda"
  value       = aws_iam_role.upload_lambda.arn
}

output "crop_lambda_role_arn" {
  description = "ARN del rol IAM de crop-lambda"
  value       = aws_iam_role.crop_lambda.arn
}

output "log_group_upload_lambda" {
  description = "Nombre del log group de upload-lambda en CloudWatch"
  value       = aws_cloudwatch_log_group.upload_lambda.name
}

output "log_group_crop_lambda" {
  description = "Nombre del log group de crop-lambda en CloudWatch"
  value       = aws_cloudwatch_log_group.crop_lambda.name
}

output "log_group_apigw" {
  description = "Nombre del log group del API Gateway en CloudWatch"
  value       = aws_cloudwatch_log_group.apigw.name
}

output "dlq_alarm_name" {
  description = "Nombre de la alarma CloudWatch del DLQ"
  value       = aws_cloudwatch_metric_alarm.dlq_messages.alarm_name
}

output "sns_topic_dlq_alarm_arn" {
  description = "ARN del SNS topic que notifica cuando el DLQ tiene mensajes"
  value       = aws_sns_topic.dlq_alarm.arn
}