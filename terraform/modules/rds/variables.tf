variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "shopfront"
}

variable "db_username" {
  type    = string
  default = "shopfront_admin"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
