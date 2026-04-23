output "function_name" {
  value = aws_lambda_function.admin_api_lambda_function.function_name
}

output "function_arn" {
  value = aws_lambda_function.admin_api_lambda_function.arn
}

output "function_url" {
  value = aws_lambda_function_url.admin_api_lambda_function_url.function_url
}
