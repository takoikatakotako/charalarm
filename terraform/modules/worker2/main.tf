##################################################
# Lambda
##################################################
resource "aws_lambda_function" "worker_lambda_function" {
  function_name = "worker-function2"
  role          = aws_iam_role.worker_lambda_role.arn
  image_uri     = "${var.worker_function_image_uri}:${var.worker_function_image_tag}"
  package_type  = "Image"
  architectures = ["arm64"]
  timeout       = 30

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
resource "aws_cloudwatch_log_group" "worker_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.worker_lambda_function.function_name}"
  retention_in_days = 90
}

# ##################################################
# # Subscription Filter
# ##################################################
# resource "aws_cloudwatch_log_subscription_filter" "log_filter" {
#   name            = "Error Subscription Filter"
#   log_group_name  = aws_cloudwatch_log_group.worker_log_group.name
#   filter_pattern  = "{ $.level = \"error\" }"
#   destination_arn = var.datadog_log_forwarder_arn
# }
