########################################
# CloudWatch アラームと通知 (失敗時のみ)
########################################

# 通知先 SNS トピック
resource "aws_sns_topic" "alert_topic" {
  name = "rds-scheduler-alerts"
}

# メール購読（要メール承認）
resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = "axenarikilo48698062@gmail.com"
}

# Lambda エラー（start）
resource "aws_cloudwatch_metric_alarm" "lambda_start_errors" {
  alarm_name          = "lambda-errors-rds-start-scheduler"
  alarm_description   = "rds-start-scheduler で Errors > 0 を検知した場合に通知"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.rds_start.function_name
  }

  alarm_actions = [aws_sns_topic.alert_topic.arn]
  ok_actions    = []
}

# Lambda エラー（stop）
resource "aws_cloudwatch_metric_alarm" "lambda_stop_errors" {
  alarm_name          = "lambda-errors-rds-stop-scheduler"
  alarm_description   = "rds-stop-scheduler で Errors > 0 を検知した場合に通知"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.rds_stop.function_name
  }

  alarm_actions = [aws_sns_topic.alert_topic.arn]
  ok_actions    = []
}

# EventBridge 失敗呼び出し（start ルール）
resource "aws_cloudwatch_metric_alarm" "events_start_failed" {
  alarm_name          = "events-failed-invocations-rds-start-schedule"
  alarm_description   = "EventBridge ルール rds-start-schedule の FailedInvocations > 0 を検知して通知"
  namespace           = "AWS/Events"
  metric_name         = "FailedInvocations"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.rds_start_schedule.name
  }

  alarm_actions = [aws_sns_topic.alert_topic.arn]
  ok_actions    = []
}

# EventBridge 失敗呼び出し（stop ルール）
resource "aws_cloudwatch_metric_alarm" "events_stop_failed" {
  alarm_name          = "events-failed-invocations-rds-stop-schedule"
  alarm_description   = "EventBridge ルール rds-stop-schedule の FailedInvocations > 0 を検知して通知"
  namespace           = "AWS/Events"
  metric_name         = "FailedInvocations"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.rds_stop_schedule.name
  }

  alarm_actions = [aws_sns_topic.alert_topic.arn]
  ok_actions    = []
}

output "sns_alert_topic_arn" {
  value = aws_sns_topic.alert_topic.arn
}

