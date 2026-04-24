resource "aws_lambda_function" "admin_api_lambda_function" {
  function_name = var.function_name
  timeout       = 30
  role          = aws_iam_role.admin_api_lambda_function_role.arn
  image_uri     = "${var.image_uri}:${var.image_tag}"
  package_type  = "Image"
  architectures = ["arm64"]

  environment {
    variables = {
      "CHARALARM_AWS_PROFILE" = "",
    }
  }

  # image_uri は GitHub Actions でデプロイするため Terraform の管理外とする
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# OAC 経由で CloudFront から呼び出すため AWS_IAM 認証
resource "aws_lambda_function_url" "admin_api_lambda_function_url" {
  function_name      = aws_lambda_function.admin_api_lambda_function.function_name
  authorization_type = "AWS_IAM"
}
