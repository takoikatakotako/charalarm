##################################################
# Lambda
##################################################
resource "aws_lambda_function" "worker_lambda_function" {
  function_name = "worker-function2"
  role          = aws_iam_role.worker_lambda_role.arn
  image_uri     = "${var.worker_function_image_uri}:${var.worker_function_image_tag}"
  package_type  = "Image"
  architectures = ["arm64"]
  timeout       = 900

  environment {
    variables = {
      "CHARALARM_AWS_PROFILE"       = "",
      "CHARALARM_RESOURCE_BASE_URL" = "https://resource.charalarm-development.swiswiswift.com"
    }
  }

  # image_uri は GitHub Actions でデプロイするため Terraform の管理外とする
  lifecycle {
    ignore_changes = [image_uri]
  }
}

##################################################
# Log Group
##################################################
resource "aws_cloudwatch_log_group" "worker_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.worker_lambda_function.function_name}"
  retention_in_days = 90
}
