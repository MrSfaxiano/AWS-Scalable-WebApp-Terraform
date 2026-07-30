resource "random_password" "db_password" {
  length  = 20
  special = false # RDS has restrictions on which special chars are allowed; keeping simple
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.project_name}-db-credentials-"
  recovery_window_in_days = 0 # allows immediate deletion when we destroy, avoids orphaned secrets during learning/teardown cycles

  tags = {
    Name = "${var.project_name}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}
