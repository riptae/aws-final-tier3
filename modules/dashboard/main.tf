# Nginx 중지 / 복구 실습: 대상 수 변화와 알람 상태를 한 화면에 표시
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    start          = "-PT1H"
    periodOverride = "inherit"
    widgets = [
      {
        type = "text", x = 0, y = 0, width = 24, height = 3
        properties = {
          markdown = "## Nginx 장애 감지 · 서비스 이중화 검증\n정상 Web 2대 → 한 대에서 `sudo systemctl stop nginx` → 비정상 대상 감지 및 SNS 알림 → ALB 주소로 서비스 유지 확인 → `sudo systemctl start nginx` → 복구 알림.\n\n헬스 체크: HTTP / · 30초 간격 · 2회 실패/성공. 알람: 비정상 대상 Minimum ≥ 1, 1분 구간 2회 연속. 수집·평가 지연이 있으며 대상 수는 개별 서버 식별 정보가 아닙니다."
        }
      },
      {
        type = "alarm", x = 0, y = 3, width = 24, height = 3
        properties = {
          title  = "Web 장애 알람 · OK / ALARM / INSUFFICIENT_DATA"
          alarms = [var.web_unhealthy_alarm_arn]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 7
        properties = {
          title  = "정상 Web 대상 수 · HealthyHostCount"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Minimum"
          period = 60
          metrics = [[
            "AWS/ApplicationELB", "HealthyHostCount",
            "LoadBalancer", var.alb_arn_suffix,
            "TargetGroup", var.target_group_arn_suffix,
            { label = "정상 Web (Minimum)", color = "#2ca02c" }
          ]]
          yAxis = { left = { min = 0 } }
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 7
        properties = {
          title  = "비정상 Web 대상 수 · UnHealthyHostCount"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Minimum"
          period = 60
          metrics = [[
            "AWS/ApplicationELB", "UnHealthyHostCount",
            "LoadBalancer", var.alb_arn_suffix,
            "TargetGroup", var.target_group_arn_suffix,
            { label = "비정상 Web (Minimum)", color = "#d62728" }
          ]]
          yAxis = { left = { min = 0 } }
          annotations = {
            horizontal = [{ label = "알람 임계값: 1대 이상", value = 1, color = "#d62728" }]
          }
        }
      }
    ]
  })
}
