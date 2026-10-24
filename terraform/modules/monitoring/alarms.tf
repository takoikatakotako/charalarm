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

##################################################
# 1日の使用量の上限に当たった回数 (全ユーザー合計)
##################################################
# API は上限を超えると "usage limit exceeded" をログに出し、429 を返す。
# ふつうの使い方ではほとんど当たらないので、急に増えたら乱用 (大量登録や API の直叩き) を疑う。
# 月ごとの予算アラート (GCP) より早く気づくためのもの。
resource "aws_cloudwatch_log_metric_filter" "usage_limit_exceeded" {
  name           = "${var.name_prefix}-usage-limit-exceeded"
  log_group_name = var.api_log_group_name
  pattern        = "\"usage limit exceeded\""

  metric_transformation {
    name          = "UsageLimitExceeded"
    namespace     = "Charalarm/${var.name_prefix}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "usage_limit_exceeded" {
  alarm_name          = "${var.name_prefix}-usage-limit-exceeded"
  alarm_description   = "1時間に ${var.usage_limit_exceeded_threshold} 回を超えて、1日の使用量の上限に当たっています (乱用の疑い)"
  namespace           = aws_cloudwatch_log_metric_filter.usage_limit_exceeded.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.usage_limit_exceeded.metric_transformation[0].name
  statistic           = "Sum"
  period              = 3600
  evaluation_periods  = 1
  threshold           = var.usage_limit_exceeded_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
