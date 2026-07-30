variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the app instances, so we can allow ALB -> app traffic"
  type        = string
}
