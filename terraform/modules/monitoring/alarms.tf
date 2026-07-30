# ASG: high CPU across the fleet — early warning before autoscaling maxes out
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "CPUUtilization"
  namespace            = "AWS/EC2"
  period               = 120
  statistic            = "Average"
  threshold            = 80
  alarm_description    = "ASG average CPU above 80% for 4 minutes"
  alarm_actions        = [aws_sns_topic.alerts.arn]
  ok_actions            = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# ALB: 5xx errors — signals app-level failures, not just infra health
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name          = "HTTPCode_Target_5XX_Count"
  namespace            = "AWS/ApplicationELB"
  period               = 60
  statistic            = "Sum"
  threshold            = 10
  alarm_description    = "More than 10 5xx errors from targets in 1 minute"
  alarm_actions        = [aws_sns_topic.alerts.arn]
  treat_missing_data    = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# ALB: unhealthy target count — catches instance-level failures immediately
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "UnHealthyHostCount"
  namespace            = "AWS/ApplicationELB"
  period               = 60
  statistic            = "Average"
  threshold            = 0
  alarm_description    = "One or more targets failing health checks"
  alarm_actions        = [aws_sns_topic.alerts.arn]
  ok_actions            = [aws_sns_topic.alerts.arn]

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }
}

# RDS: high CPU — early signal of database-level issues
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "CPUUtilization"
  namespace            = "AWS/RDS"
  period               = 120
  statistic            = "Average"
  threshold            = 80
  alarm_description    = "RDS CPU above 80% for 4 minutes"
  alarm_actions        = [aws_sns_topic.alerts.arn]
  ok_actions            = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# RDS: free storage space running low — prevents a surprise outage
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  metric_name          = "FreeStorageSpace"
  namespace            = "AWS/RDS"
  period               = 300
  statistic            = "Average"
  threshold            = 2000000000 # 2 GB in bytes
  alarm_description    = "RDS free storage below 2GB"
  alarm_actions        = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}
