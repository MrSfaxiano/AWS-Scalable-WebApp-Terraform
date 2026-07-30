resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.project_name}-asg-"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  health_check_type   = "EC2"
  health_check_grace_period = 60
  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target tracking scaling policy — scale based on average CPU utilization
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
