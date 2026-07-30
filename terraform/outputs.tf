output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "route53_nameservers" {
  value = module.route53.name_servers
}

output "dashboard_url" {
  value = module.monitoring.dashboard_url
}






