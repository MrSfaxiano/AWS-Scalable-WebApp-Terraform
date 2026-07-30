module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  target_group_arn   = module.alb.target_group_arn
}

module "alb" {
  source = "./modules/alb"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  app_security_group_id  = module.compute.app_security_group_id
}

module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  alb_arn      = module.alb.alb_arn
}

module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  app_security_group_id  = module.compute.app_security_group_id
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project_name = var.project_name
  alb_dns_name = module.alb.alb_dns_name
}

module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name             = var.project_name
  alert_email              = var.alert_email
  asg_name                 = module.compute.asg_name
  alb_arn_suffix           = module.alb.alb_arn_suffix
  target_group_arn_suffix  = module.alb.target_group_arn_suffix
  db_instance_id           = module.rds.db_instance_id
}
