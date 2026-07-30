variable "project_name" {
  type = string
}

variable "alert_email" {
  description = "Email to receive CloudWatch alarm notifications"
  type        = string
}

variable "asg_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "db_instance_id" {
  type = string
}
