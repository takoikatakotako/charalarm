output "function_name" {
  value = aws_lambda_function.api_lambda_function.function_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.api_cloudfront_distribution.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.api_log_group.name
}
