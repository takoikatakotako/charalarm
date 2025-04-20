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
  # environment {
  #   variables = local.environment_variables
  # }


  environment {
    variables = {
      "CHARALARM_AWS_PROFILE" = "",
      "RESOURCE_BASE_URL"     = "https://resource.charalarm-development.swiswiswift.com"
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

# resource "aws_cloudwatch_log_subscription_filter" "datadog_log_subscription_filter" {
#   name            = "datadog_log_subscription_filter"
#   log_group_name  = <CLOUDWATCH_LOG_GROUP_NAME> # for example, /aws/lambda/my_lambda_name
#   destination_arn = <DATADOG_FORWARDER_ARN> # for example,  arn:aws:lambda:us-east-1:123:function:datadog-forwarder
#   filter_pattern  = ""
# }



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








# ##################################################
# # Permission
# ##################################################
# resource "aws_lambda_permission" "lambda_permission" {
#   statement_id  = "api-gateway-${var.function_name}-statement-id"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_function.arn
#   principal     = "apigateway.amazonaws.com"

#   # The /*/*/* part allows invocation from any stage, method and resource path
#   source_arn = "${var.execution_arn}/*/${var.method}${var.path}"
# }
