output "sns_topic_arn" {
  value = aws_sns_topic.alarm.arn
}

# 대시보드에서 알람 상태를 표시할 때 사용할 출력
output "web_unhealthy_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.web_unhealthy.arn
}

output "web_unhealthy_alarm_name" {
  value = aws_cloudwatch_metric_alarm.web_unhealthy.alarm_name
}
