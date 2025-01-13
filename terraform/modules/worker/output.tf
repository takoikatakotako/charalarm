output "worker_lambda_function_arn" {
  value       = aws_lambda_function.worker_lambda_function.arn
  description = "Worker Lambda Function ARN"
}