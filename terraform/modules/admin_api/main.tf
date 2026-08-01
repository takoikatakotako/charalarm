# CloudFront から注入される共有秘密(= admin Basic 認証パスワードを流用)を
# apply 時に読み、Lambda 環境変数へ渡す。生 Function URL の直叩き防止に使う。
data "aws_ssm_parameter" "origin_secret" {
  name = var.origin_secret_ssm_parameter_name
}

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
      "ADMIN_ORIGIN_SECRET"   = data.aws_ssm_parameter.origin_secret.value,
    }
  }

  # image_uri は GitHub Actions でデプロイするため Terraform の管理外とする
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# OAC(SigV4)は POST のボディに署名できず Lambda URL が 403 を返すため、
# 認証は NONE にし、CloudFront 関数が注入する共有秘密ヘッダを admin_api 側で検証する。
resource "aws_lambda_function_url" "admin_api_lambda_function_url" {
  function_name      = aws_lambda_function.admin_api_lambda_function.function_name
  authorization_type = "NONE"
}

# auth=NONE の Function URL を公開呼び出し可能にする(実際の保護は共有秘密ヘッダ)
resource "aws_lambda_permission" "admin_api_function_url_public" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.admin_api_lambda_function.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
