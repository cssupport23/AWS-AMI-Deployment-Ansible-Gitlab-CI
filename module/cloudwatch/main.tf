resource "aws_cloudwatch_metric_alarm" "blue_cpu_high" {
    alarm_name                = "${var.name}_high_cpu_utilization"
    comparison_operator       = "GreaterThanThreshold"
    evaluation_periods        = "2"
    metric_name               = "CPUUtilization"
    namespace                 = "AWS/EC2"
    period                    = "60"
    statistic                 = "Average"
    threshold                 = "80"  # Set your desired CPU usage threshold
    actions_enabled           = true
    alarm_actions             = [var.sns_topic_arn]  # Replace with SNS topic
    dimensions = {
      InstanceId = var.instance_id  # Replace with instance IDs
    }
  }
  
  resource "aws_cloudwatch_metric_alarm" "blue_memory_high" {
    alarm_name                = "${var.name}_high_memory_utilization"
    comparison_operator       = "GreaterThanThreshold"
    evaluation_periods        = "2"
    metric_name               = "mem_used_percent"
    namespace                 = "CWAgent"
    period                    = "60"
    statistic                 = "Average"
    threshold                 = "85"  # Set your desired memory usage threshold
    actions_enabled           = true
    alarm_actions             = [var.sns_topic_arn]  # Replace with SNS topic
    dimensions = {
      InstanceId = var.instance_id  # Replace with instance IDs
    }
  }
  
  resource "aws_cloudwatch_metric_alarm" "blue_disk_usage_high" {
    alarm_name                = "${var.name}_high_disk_usage"
    comparison_operator       = "GreaterThanThreshold"
    evaluation_periods        = "2"
    metric_name               = "disk_used_percent"
    namespace                 = "CWAgent"
    period                    = "60"
    statistic                 = "Average"
    threshold                 = "85"  # Set your desired disk usage threshold
    actions_enabled           = true
    alarm_actions             = [var.sns_topic_arn]  # Replace with SNS topic
    dimensions = {
      InstanceId = var.instance_id  # Replace with instance IDs
    }
  }


  resource "aws_cloudwatch_log_stream" "green_log_stream" {
    name           = "${var.instance_id}/pm2"
    log_group_name = var.log_group_name
  }

  
  
  
  
