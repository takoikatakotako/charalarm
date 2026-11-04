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
      "CHARALARM_AWS_PROFILE"       = "",
      "CHARALARM_RESOURCE_BASE_URL" = var.resource_base_url
      # 話題のニュース (trendNews)。X の Bearer Token は "ssm://" で Parameter Store から読む
      "CHARALARM_X_BEARER_TOKEN"        = var.x_bearer_token_ssm_parameter_name == "" ? "" : "ssm://${var.x_bearer_token_ssm_parameter_name}",
      "CHARALARM_RESOURCE_BUCKET_NAME"  = var.resource_bucket_name,
      "CHARALARM_GCP_PROJECT"           = var.gcp_project,
      "CHARALARM_GCP_CREDENTIAL_CONFIG" = var.gcp_credential_config,
      "CHARALARM_LLM_MODEL"             = var.llm_model
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
resource "aws_cloudwatch_log_group" "batch_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.batch_lambda_function.function_name}"
  retention_in_days = 30
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


##################################################
# 話題のニュース (1 日 4 回)
# X のニュースを取り、子ども（9+）が朝に聞いてよいものを Gemini で選んで resource のバケットに置く。
# X の Bearer Token のパラメータ名が空なら作らない
##################################################
resource "aws_cloudwatch_event_rule" "trend_news_event_rule" {
  count               = var.x_bearer_token_ssm_parameter_name == "" ? 0 : 1
  name                = "trend-news-event-rule"
  description         = "trend news event rule"
  schedule_expression = "cron(0 1,7,13,19 * * ? *)" # 日本時間 4・10・16・22 時
}

resource "aws_cloudwatch_event_target" "trend_news_event_target" {
  count     = var.x_bearer_token_ssm_parameter_name == "" ? 0 : 1
  target_id = "trend-news-event-target"
  rule      = aws_cloudwatch_event_rule.trend_news_event_rule[0].name
  arn       = aws_lambda_function.batch_lambda_function.arn
  input     = jsonencode({ job = "trendNews" })
}

resource "aws_lambda_permission" "trend_news_lambda_permission" {
  count         = var.x_bearer_token_ssm_parameter_name == "" ? 0 : 1
  statement_id  = "AllowTrendNewsFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.batch_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trend_news_event_rule[0].arn
}
