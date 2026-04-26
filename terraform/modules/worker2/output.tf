output "worker_lambda_function_arn" {
  value       = aws_lambda_function.worker_lambda_function.qualified_arn
  description = "Worker Lambda Function ARN"
}

output "function_name" {
  value = aws_lambda_function.worker_lambda_function.function_name
}
