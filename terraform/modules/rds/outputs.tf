output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "db_instance_id" {
  value = aws_db_instance.main.identifier
}
