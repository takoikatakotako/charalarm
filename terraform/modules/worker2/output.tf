output "worker_lambda_function_arn" {
  value       = aws_lambda_function.worker_lambda_function.qualified_arn
  description = "Worker Lambda Function ARN"
}

# aws_lambda_function.lambda_edge_function.qualified_arn
