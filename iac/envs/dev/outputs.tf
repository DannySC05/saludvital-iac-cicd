output "api_invoke_url" {
  value = module.app.api_invoke_url
}

output "sqs_queue_url" {
  value = module.app.sqs_queue_url
}

output "s3_bucket_name" {
  value = module.app.s3_bucket_name
}
