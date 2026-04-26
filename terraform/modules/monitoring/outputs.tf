output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "slack_notifier_function_name" {
  value = aws_lambda_function.slack_notifier.function_name
}
