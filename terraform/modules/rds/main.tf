resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.project_name}-db-subnet-"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier_prefix = "${var.project_name}-db-"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type       = "gp3"
  storage_encrypted  = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 0
  skip_final_snapshot     = true # set to false for real prod; true here to allow clean teardown during learning

  publicly_accessible = false

  tags = {
    Name = "${var.project_name}-db"
  }
}
