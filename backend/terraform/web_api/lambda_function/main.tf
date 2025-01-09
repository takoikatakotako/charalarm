##################################################
# Lambda
##################################################
resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name
  role          = var.role
  runtime       = "provided.al2"
  handler       = "bootstrap"
  timeout       = 15

  # Lambda生成に必要なのでダミーファイルを渡している。デプロイはCLIから行う。
  filename         = "${path.module}/source/dummy.zip"
  source_code_hash = sha256(filebase64("${path.module}/source/dummy.zip"))
  publish          = false
  architectures = [
    "arm64"
  ]

  environment {
    variables = var.environment_variables
  }

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
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 90
}

##################################################
# Subscription Filter
##################################################
resource "aws_cloudwatch_log_subscription_filter" "log_filter" {
  name           = "Error Subscription Filter"
  log_group_name = aws_cloudwatch_log_group.log_group.name
  # filter_pattern  = "{ $.level = \"error\" }"
  filter_pattern  = ""
  destination_arn = var.datadog_log_forwarder_arn
}


##################################################
# Permission
##################################################
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "api-gateway-${var.function_name}-statement-id"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  source_arn = "${var.execution_arn}/*/${var.method}${var.path}"
}



# aws lambda get-policy --function-name user-signup-anonymous-post-function --profile sandbox | jq


# user-signup-anonymous-post-function/e081b2d8-db12-4c3e-a167-130bb7a56591

# terraform import module.web_api.module.user_signup_anonymous_post_lambda_function.aws_lambda_permission.lambda_permission user-signup-anonymous-post-function/e081b2d8-db12-4c3e-a167-130bb7a56591
