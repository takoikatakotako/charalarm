##################################################
# Lambda
##################################################
resource "aws_lambda_function" "batch_lambda_function" {
  function_name = "batch-function2"
  timeout       = 900
  role          = aws_iam_role.batch_lambda_role.arn
  image_uri     = "${var.batch_function_image_uri}:${var.batch_function_image_tag}"
  package_type  = "Image"
  architectures = ["arm64"]

  environment {
    variables = {
      "CHARALARM_AWS_PROFILE" = "",
      "RESOURCE_BASE_URL"     = var.resource_base_url
    }
  }
}


##################################################
# Log Group
##################################################
resource "aws_cloudwatch_log_group" "batch_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.batch_lambda_function.function_name}"
  retention_in_days = 90
}


##################################################
# Event Target
##################################################
resource "aws_cloudwatch_event_rule" "batch_event_rule" {
  name                = "batch-event-rule"
  description         = "batch event rule"
  schedule_expression = "cron(* * * * ? *)" # 毎分実行
}

resource "aws_cloudwatch_event_target" "batch_event_target" {
  target_id = "batch-event-target"
  rule      = aws_cloudwatch_event_rule.batch_event_rule.name
  arn       = aws_lambda_function.batch_lambda_function.arn
}

resource "aws_lambda_permission" "batch_lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.batch_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.batch_event_rule.arn
}


