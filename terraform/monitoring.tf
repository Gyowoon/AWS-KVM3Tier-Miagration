#===============================================================================
# monitoring.tf - CloudWatch, SNS, Lambda
#===============================================================================
# Phase 1 대응: CloudWatch Alarms, SNS Topic, Lambda Slack Notifier
# 구성:
#   - SNS Topic: 알림 수신
#   - CloudWatch Alarms: EC2 CPU, RDS CPU, RDS Storage, ALB 5xx
#   - Lambda: Slack 웹훅 전송 (선택)
#===============================================================================

#===============================================================================
# SNS Topic
#===============================================================================
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

#---------------------------------------
# SNS Email Subscription (선택)
#---------------------------------------
# 이메일 알림을 받으려면 아래 주석 해제 후 email 변수 추가
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = var.alert_email
# }

#===============================================================================
# CloudWatch Alarms - EC2
#===============================================================================

#---------------------------------------
# Web-A CPU Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "web_a_cpu" {
  alarm_name          = "${var.project_name}-web-a-cpu-high"
  alarm_description   = "Web-A EC2 CPU utilization high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5분
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    InstanceId = aws_instance.web_a.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-web-a-cpu-high"
    Tier = "Web"
  }
}

#---------------------------------------
# Web-C CPU Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "web_c_cpu" {
  alarm_name          = "${var.project_name}-web-c-cpu-high"
  alarm_description   = "Web-C EC2 CPU utilization high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    InstanceId = aws_instance.web_c.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-web-c-cpu-high"
    Tier = "Web"
  }
}

#---------------------------------------
# App-A CPU Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "app_a_cpu" {
  alarm_name          = "${var.project_name}-app-a-cpu-high"
  alarm_description   = "App-A EC2 CPU utilization high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    InstanceId = aws_instance.app_a.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-app-a-cpu-high"
    Tier = "App"
  }
}

#---------------------------------------
# App-C CPU Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "app_c_cpu" {
  alarm_name          = "${var.project_name}-app-c-cpu-high"
  alarm_description   = "App-C EC2 CPU utilization high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    InstanceId = aws_instance.app_c.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-app-c-cpu-high"
    Tier = "App"
  }
}

#===============================================================================
# CloudWatch Alarms - RDS
#===============================================================================

#---------------------------------------
# RDS CPU Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  alarm_description   = "RDS CPU utilization high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-rds-cpu-high"
    Tier = "Database"
  }
}

#---------------------------------------
# RDS Free Storage Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  alarm_description   = "RDS free storage space low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120  # 5GB in bytes
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-rds-storage-low"
    Tier = "Database"
  }
}

#---------------------------------------
# RDS Database Connections Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  alarm_description   = "RDS database connections high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50  # db.t3.micro 기준 적정 값
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-rds-connections-high"
    Tier = "Database"
  }
}

#===============================================================================
# CloudWatch Alarms - ALB
#===============================================================================

#---------------------------------------
# External ALB 5xx Error Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-high"
  alarm_description   = "External ALB 5xx errors high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"  # 데이터 없으면 정상으로 처리
  
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-high"
    Tier = "ALB"
  }
}

#---------------------------------------
# External ALB Target 5xx Error Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "${var.project_name}-alb-target-5xx-high"
  alarm_description   = "ALB Target (Web tier) 5xx errors high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-alb-target-5xx-high"
    Tier = "ALB"
  }
}

#---------------------------------------
# ALB Unhealthy Host Count Alarm
#---------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-alb-unhealthy-hosts"
    Tier = "ALB"
  }
}

#===============================================================================
# Lambda for Slack Notification (선택)
#===============================================================================
# Slack 웹훅 알림을 사용하려면 아래 주석 해제 및 변수 추가 필요
# 
# 1. variables.tf에 추가:
#    variable "slack_webhook_url" {
#      description = "Slack Incoming Webhook URL"
#      type        = string
#      sensitive   = true
#    }
#
# 2. terraform.tfvars에 추가:
#    slack_webhook_url = "https://hooks.slack.com/services/..."
#
# 3. 아래 Lambda 리소스 주석 해제

# #---------------------------------------
# # Lambda IAM Role
# #---------------------------------------
# resource "aws_iam_role" "lambda_slack" {
#   name = "${var.project_name}-lambda-slack-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
#
#   tags = {
#     Name = "${var.project_name}-lambda-slack-role"
#   }
# }
#
# resource "aws_iam_role_policy_attachment" "lambda_basic" {
#   role       = aws_iam_role.lambda_slack.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }
#
# #---------------------------------------
# # Lambda Function
# #---------------------------------------
# data "archive_file" "lambda_slack" {
#   type        = "zip"
#   output_path = "${path.module}/lambda_slack.zip"
#
#   source {
#     content  = <<-EOF
#       import json
#       import urllib.request
#       import os
#
#       def lambda_handler(event, context):
#           webhook_url = os.environ['SLACK_WEBHOOK_URL']
#           
#           message = event['Records'][0]['Sns']['Message']
#           subject = event['Records'][0]['Sns']['Subject'] or 'AWS Alert'
#           
#           slack_message = {
#               'text': f'*{subject}*\n```{message}```'
#           }
#           
#           req = urllib.request.Request(
#               webhook_url,
#               data=json.dumps(slack_message).encode('utf-8'),
#               headers={'Content-Type': 'application/json'}
#           )
#           
#           urllib.request.urlopen(req)
#           return {'statusCode': 200}
#     EOF
#     filename = "lambda_function.py"
#   }
# }
#
# resource "aws_lambda_function" "slack_notifier" {
#   filename         = data.archive_file.lambda_slack.output_path
#   function_name    = "${var.project_name}-slack-notifier"
#   role             = aws_iam_role.lambda_slack.arn
#   handler          = "lambda_function.lambda_handler"
#   source_code_hash = data.archive_file.lambda_slack.output_base64sha256
#   runtime          = "python3.12"
#   timeout          = 10
#
#   environment {
#     variables = {
#       SLACK_WEBHOOK_URL = var.slack_webhook_url
#     }
#   }
#
#   tags = {
#     Name = "${var.project_name}-slack-notifier"
#   }
# }
#
# #---------------------------------------
# # SNS → Lambda Subscription
# #---------------------------------------
# resource "aws_sns_topic_subscription" "lambda_slack" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.slack_notifier.arn
# }
#
# resource "aws_lambda_permission" "sns_invoke" {
#   statement_id  = "AllowSNSInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.slack_notifier.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.alerts.arn
# }
