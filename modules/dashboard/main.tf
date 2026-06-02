resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
        {
            type = "metric"
            x = 0
            y = 0
            width = 12
            height = 6

            properties = {
                title = "ALB Request Count"
                view = "timeSeries"
                region = var.aws_region
                stat = "Sum"
                period = 60

                metrics = [
                    [
                        "AWS/ApplicationELB",
                        "RequestCount",
                        "LoadBalancer",
                        var.alb_arn_suffix
                    ]
                ]
            }
        },

        {
            type = "metric"
            x = 2
            y = 0
            width = 12
            height = 6

            properties = {
                title = "ALB Target Response Time"
                view = "timeSeries"
                region = var.aws_region
                stat = "Average"
                period = 60

                metrics = [
                    [
                      "AWS/ApplicationELB",
                      "TargetResponseTime",
                      "LoadBalancer",
                      var.alb_arn_suffix,
                      "TargetGroup",
                      var.target_group_arn_suffix  
                    ]
                ]
            }
        },

        {
            type = "metric"
            x = 0
            y = 6
            width = 12
            height = 6

            properties = {
                title = "ALB 5XX Errors"
                view = "timeSeries"
                region = var.aws_region
                stat = "Sum"
                period = 60

                metrics = [
                    [
                        "AWS/ApplicationELB",
                        "HTTPCode_ELB_5XX_Count",
                        "LoadBalancer",
                        var.alb_arn_suffix
                    ],
                    [
                        "AWS/ApplicationELB",
                        "HTTPCode_Target_5XX_Count",
                        "LoadBalancer",
                        var.alb_arn_suffix,
                        "TargetGroup",
                        var.target_group_arn_suffix
                    ]
                
                ]
            }
        },

        {
            type = "metric"
            x = 12
            y = 6
            width = 12
            height = 6

            properties = {
                title = "Web EC2 CPU"
                view = "timeSeries"
                region = var.aws_region
                stat = "Average"
                period = 60

                metrics = [
                    for id in var.web_instance_ids : [
                        "AWS/EC2",
                        "CPUUtilization",
                        "InstanceId",
                        id
                    ]
                ]
            }
        },

        {
            type = "metric"
            x = 0
            y = 12
            width = 12
            height = 6

            properties = {
                title = "APP EC2 CPU"
                view = "timeSeries"
                region = var.aws_region
                stat = "Average"
                period = 60

                metrics = [
                    for id in var.app_instance_ids : [
                        "AWS/EC2",
                        "CPUUtilization",
                        "InstanceId",
                        id
                    ]
                ]
            }
        },

        {
            type = "metric"
            x = 12
            y = 12
            width = 12 
            height = 6

            properties = {
                title = "RDS CPU"
                view = "timeSeries"
                region = var.aws_region
                stat = "Average"
                period = 60

                metrics = [
                    [
                    "AWS/RDS",
                    "CPUUtilization",
                    "DBInstanceIdentifier",
                    var.db_instance_id
                    ]
                    
                ]
            }
        },

        {
            type = "metric"
            x = 0
            y = 18
            width = 12
            height = 6

            properties = {
                title = "RDS Free Storage"
                view = "timeSeries"
                region = var.aws_region
                stat = "Average"
                period = 300

                metrics = [
                    [
                        "AWS/RDS",
                        "FreeStorageSpace",
                        "DBInstanceIdentifier",
                        var.db_instance_id
                    ]
                ]
            }
        },

        {
            type = "metric"
            x = 12
            y = 18
            width = 12
            height = 6

            properties = {
                title = "RDS Database Connections"
                view = "timeSeries"
                region = var.aws_region
                stat = "Average"
                period = 60

                metrics = [
                    [
                        "AWS/RDS",
                        "DatabaseConnections",
                        "DBInstanceIdentifier",
                        var.db_instance_id
                    ]
                ]
            }
        }
    ]
  })
}