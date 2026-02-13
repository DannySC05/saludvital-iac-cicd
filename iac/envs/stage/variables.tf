variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod)"
}

variable "project" {
  type        = string
  description = "Project name"
}
