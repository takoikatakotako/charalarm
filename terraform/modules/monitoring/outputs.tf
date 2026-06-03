output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  value = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "slack_notifier_function_name" {
  value = aws_lambda_function.slack_notifier.function_name
}
