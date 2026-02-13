output "sqs_queue_url" {
  value = aws_sqs_queue.queue.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.evidence.bucket
}

# Placeholder por ahora: API Gateway lo añadimos en Etapa 2
output "api_invoke_url" {
  value = "PENDING_API_GATEWAY"
}
