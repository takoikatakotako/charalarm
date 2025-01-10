##################################################
# Lambda
##################################################
resource "aws_lambda_function" "worker_lambda_function" {
  function_name = "worker-function"
  role          = aws_iam_role.worker_lambda_role.arn
  runtime       = "provided.al2"
  handler       = "bootstrap"
  timeout       = 30

  # Lambda生成に必要なのでダミーファイルを渡している。デプロイはCLIから行う。
  filename         = "${path.module}/source/dummy.zip"
  source_code_hash = sha256(filebase64("${path.module}/source/dummy.zip"))
  publish          = false
  architectures = [
    "arm64"
  ]
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      s3_bucket,
      s3_key
    ]
  }
}


##################################################
# Log Group
##################################################
resource "aws_cloudwatch_log_group" "worker_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.worker_lambda_function.function_name}"
  retention_in_days = 90
}

##################################################
# Subscription Filter
##################################################
resource "aws_cloudwatch_log_subscription_filter" "log_filter" {
  name            = "Error Subscription Filter"
  log_group_name  = aws_cloudwatch_log_group.worker_log_group.name
  filter_pattern  = "{ $.level = \"error\" }"
  destination_arn = var.datadog_log_forwarder_arn
}
