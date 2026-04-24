data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "admin_api_lambda_function_role" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.admin_api_lambda_function_role_assume_policy_document.json
}

data "aws_iam_policy_document" "admin_api_lambda_function_role_assume_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "admin_api_lambda_function_role_policy" {
  name   = "${var.function_name}-role-policy"
  policy = data.aws_iam_policy_document.admin_api_lambda_function_role_policy_document.json
}

data "aws_iam_policy_document" "admin_api_lambda_function_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = ["arn:aws:logs:ap-northeast-1:${local.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    resources = [
      "arn:aws:logs:ap-northeast-1:${local.account_id}:log-group:/aws/lambda/${aws_lambda_function.admin_api_lambda_function.function_name}:*"
    ]
  }

  statement {
    sid    = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["*"]
  }

  # 管理画面は読み取りのみ。書き込みが必要になったら拡張する
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "admin_api_lambda_function_role_policy_attachment" {
  role       = aws_iam_role.admin_api_lambda_function_role.name
  policy_arn = aws_iam_policy.admin_api_lambda_function_role_policy.arn
}
