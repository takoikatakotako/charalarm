##################################################
# SQS DLQ に1件でも溜まったら通知
##################################################
resource "aws_cloudwatch_metric_alarm" "voip_push_dlq_has_messages" {
  alarm_name          = "${var.name_prefix}-voip-push-dlq-has-messages"
  alarm_description   = "VoIP Push DLQ にメッセージがあります (配信失敗 or デコード失敗)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = var.voip_push_dlq_name
  }
}

##################################################
# Worker Lambda のエラー発生
##################################################
resource "aws_cloudwatch_metric_alarm" "worker_errors" {
  alarm_name          = "${var.name_prefix}-worker-errors"
  alarm_description   = "Worker Lambda でエラーが発生しています (VoIP Push 配信失敗)"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.worker_function_name
  }
}

##################################################
# Batch Lambda が毎分動いていない (ハートビート監視)
##################################################
resource "aws_cloudwatch_metric_alarm" "batch_heartbeat" {
  alarm_name          = "${var.name_prefix}-batch-heartbeat"
  alarm_description   = "Batch Lambda が 10 分以上起動していません (EventBridge 停止 or Lambda 障害)"
  namespace           = "AWS/Lambda"
  metric_name         = "Invocations"
  statistic           = "Sum"
  period              = 600
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.batch_function_name
  }
}
