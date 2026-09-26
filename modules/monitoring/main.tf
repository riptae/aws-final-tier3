# 1. 장애 발생 / 정상 복구 알림을 전달할 SNS Topic
resource "aws_sns_topic" "alarm" {
  name = "${var.name_prefix}-alarm-topic"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alarm-topic"
  })
}

# 2. 이메일 구독: 수신한 확인 메일에서 구독을 승인해야 함
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# 3. Nginx 중지 → ALB HTTP 헬스 체크 실패 → 비정상 대상 감지
# 헬스 체크 경로와 실패 횟수는 ALB 모듈의 대상 그룹에서 설정함.
resource "aws_cloudwatch_metric_alarm" "web_unhealthy" {
  alarm_name        = "${var.name_prefix}-web-unhealthy"
  alarm_description = "Web target unhealthy: check ALB target health and Nginx on Web instances."

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  # AWS 권장: 모든 ALB 노드에서 비정상이 관측되는지 Minimum으로 확인.
  # 1분 구간 두 번 연속으로 비정상 대상이 1개 이상이면 ALARM.
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  # 데이터 부재를 정상이나 장애로 간주하지 않음.
  treat_missing_data = "missing"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = var.common_tags
}
