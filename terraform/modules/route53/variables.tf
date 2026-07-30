variable "project_name" {
  type = string
}

variable "domain_name" {
  description = "Placeholder domain — not publicly resolvable since we don't own it, used to demonstrate the resource"
  type        = string
  default     = "spooky-shopfront-demo.com"
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}
