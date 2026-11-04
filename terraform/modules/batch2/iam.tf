##################################################
# Lambdaにアタッチするためのロール
##################################################
resource "aws_iam_role" "batch_lambda_role" {
  name               = "batch-lambda-role2"
  assume_role_policy = data.aws_iam_policy_document.batch_lambda_role_assume_policy_document.json
}

data "aws_iam_policy_document" "batch_lambda_role_assume_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "batch_lambda_role_policy" {
  name   = "batch-lambda-role-policy2"
  policy = data.aws_iam_policy_document.batch_lambda_role_iam_policy_document.json
}

data "aws_iam_policy_document" "batch_lambda_role_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
      "sqs:*",
    ]
    resources = ["*"]
  }
}

# 話題のニュース: X の Bearer Token を読み、resource のバケットの trend-news/ に JSON を置く
resource "aws_iam_role_policy" "batch_lambda_trend_news_policy" {
  count  = var.x_bearer_token_ssm_parameter_name == "" ? 0 : 1
  name   = "batch-lambda-trend-news-policy"
  role   = aws_iam_role.batch_lambda_role.id
  policy = data.aws_iam_policy_document.batch_lambda_trend_news_policy_document.json
}

data "aws_iam_policy_document" "batch_lambda_trend_news_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.current.account_id}:parameter${var.x_bearer_token_ssm_parameter_name}"]
  }

  # SecureString(既定の aws/ssm キー)を復号する
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.target_key_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.resource_bucket_name}/trend-news/*"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

resource "aws_iam_role_policy_attachment" "batch_lambda_role_policy_attachment" {
  role       = aws_iam_role.batch_lambda_role.name
  policy_arn = aws_iam_policy.batch_lambda_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "batch_lambda_role_basic_execution_policy_attachment" {
  role       = aws_iam_role.batch_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
