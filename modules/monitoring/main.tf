resource "aws_sns_topic" "alarm" {
  name = "${var.name_prefix}-alarm-topic"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alarm-topic"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol = "email"
  endpoint = var.notification_email
}

#########################
# ALB 5XX Alarm
#########################
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name = "${var.name_prefix}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1 
  metric_name = "HTTPCode_ELB_5XX_Count"
  namespace = "AWS/ApplicationELB"
  period = 60
  statistic = "Sum"
  threshold = 5
  alarm_description = "ALB 5XX errors are high"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions = [aws_sns_topic.alarm.arn]

  tags = var.common_tags

}

#########################
# Target 5XX Alarm
#########################
resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name = "${var.name_prefix}-target-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  metric_name = "HTTPCode_Target_5XX_Count"
  namespace = "AWS/ApplicationELB"
  period = 60
  statistic = "Sum"
  threshold = 5
  alarm_description = "Target 5XX errors are high"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions = [aws_sns_topic.alarm.arn]

  tags = var.common_tags
}

#########################
# Web EC2 CPU Alarm
#########################
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
    count = length(var.web_instance_ids)

    alarm_name = "${var.name_prefix}-web-${count.index + 1}-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = 60
    statistic = "Average"
    threshold = 80
    alarm_description = "Web EC2 CPU Utiliztion is high"
    
    dimensions = {
      InstanceId = var.web_instance_ids[count.index]
    }

    alarm_actions = [aws_sns_topic.alarm.arn]
    ok_actions = [aws_sns_topic.alarm.arn]

    tags = var.common_tags
  
}

#########################
# APP EC2 Alarm
#########################
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  count = length(var.app_instance_ids)

  alarm_name = "${var.name_prefix}-app-${count.index + 1}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 80
  alarm_description = "APP EC2 CPU Utilization is high"

  dimensions = {
    InstanceId = var.app_instance_ids[count.index]
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions = [aws_sns_topic.alarm.arn]

  tags = var.common_tags
}

#########################
# RDS CPU Alarm
#########################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name = "${var.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/RDS"
  period = 60
  statistic = "Average"
  threshold = 80
  alarm_description = "RDS CPU Utilization is high"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions = [aws_sns_topic.alarm.arn]

  tags = var.common_tags
}

#########################
# RDS FreeStorageSpace Alarm
#########################
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name = "${var.name_prefix}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 1
  metric_name = "FreeStorageSpace"
  namespace = "AWS/RDS"
  period = 300
  statistic = "Average"
  threshold = 5000000000
  alarm_description = "RDS free storage is lower than 5GB"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

    alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions = [aws_sns_topic.alarm.arn]

  tags = var.common_tags
}