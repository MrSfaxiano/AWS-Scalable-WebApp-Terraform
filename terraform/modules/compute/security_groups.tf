# Security group for the app instances — will only allow traffic from the ALB (added in Session 3)
resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "Security group for app instances"
  vpc_id      = var.vpc_id

  # Outbound: allow everything (instances need to reach NAT for updates, RDS, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
