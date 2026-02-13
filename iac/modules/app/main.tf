locals {
  name_prefix = "${var.project}-${var.environment}"
}

# -------------------------
# S3 Buckets
# -------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-artifacts-${random_id.suffix.hex}"
  tags = {
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_s3_bucket" "evidence" {
  bucket = "${local.name_prefix}-evidence-${random_id.suffix.hex}"
  tags = {
    Project = var.project
    Env     = var.environment
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

# -------------------------
# SQS + DLQ
# -------------------------
resource "aws_sqs_queue" "dlq" {
  name = "${local.name_prefix}-lab-dlq"
}

resource "aws_sqs_queue" "queue" {
  name = "${local.name_prefix}-lab-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

# -------------------------
# IAM Role for Lambda
# -------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Basic execution (CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow SQS access (receive/send/delete) for lab functions
data "aws_iam_policy_document" "lambda_sqs_policy" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.queue.arn,
      aws_sqs_queue.dlq.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_sqs" {
  name   = "${local.name_prefix}-lambda-sqs"
  policy = data.aws_iam_policy_document.lambda_sqs_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs.arn
}

# -------------------------
# Lambda functions (4)
# -------------------------
resource "aws_lambda_function" "appointment" {
  function_name = "${local.name_prefix}-appointment"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = "${path.module}/../../../services/lambdas/zips/appointment.zip"
source_code_hash = filebase64sha256("${path.module}/../../../services/lambdas/zips/appointment.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }
}

resource "aws_lambda_function" "lab_ingest" {
  function_name = "${local.name_prefix}-lab-ingest"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = "${path.module}/../../../services/lambdas/zips/appointment.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../services/lambdas/zips/appointment.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      LAB_QUEUE_URL = aws_sqs_queue.queue.id
    }
  }
}

resource "aws_lambda_function" "lab_process" {
  function_name = "${local.name_prefix}-lab-process"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = "${path.module}/../../../services/lambdas/zips/appointment.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../services/lambdas/zips/appointment.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }
}

resource "aws_lambda_function" "patient_summary" {
  function_name = "${local.name_prefix}-patient-summary"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

    filename         = "${path.module}/../../../services/lambdas/zips/appointment.zip"
    source_code_hash = filebase64sha256("${path.module}/../../../services/lambdas/zips/appointment.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }
}

# Optional: SQS trigger mapping for processor (makes it deployable)
resource "aws_lambda_event_source_mapping" "sqs_to_lab_process" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.lab_process.arn
  batch_size       = 10
  enabled          = true
}
