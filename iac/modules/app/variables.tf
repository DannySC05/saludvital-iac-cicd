variable "project" { type = string }
variable "environment" { type = string }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "lambda_sg_id" { type = string }
variable "rds_sg_id" { type = string }

# Lambda settings (puedes ajustar después)
variable "lambda_runtime" {
  type    = string
  default = "python3.11"
}

variable "lambda_memory_mb" {
  type    = number
  default = 512
}

variable "lambda_timeout_seconds" {
  type    = number
  default = 10
}
