resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.project_name}-zone"
  }
}

# Health check against the ALB directly — Route 53 pings this to know if failover should trigger
resource "aws_route53_health_check" "alb" {
  fqdn              = var.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-alb-health-check"
  }
}

# Alias record — points our domain at the ALB, zero additional cost (unlike a regular A record with data transfer)
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
