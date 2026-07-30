variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name used as a prefix for resource naming"
  type        = string
  default     = "spooky"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}
