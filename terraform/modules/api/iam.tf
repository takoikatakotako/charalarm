
resource "aws_iam_role" "api_lambda_function_role" {
  name               = "charalarm-api-role"
  assume_role_policy = data.aws_iam_policy_document.api_lambda_function_role_assume_policy_document.json
}

data "aws_iam_policy_document" "api_lambda_function_role_assume_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "api_lambda_function_role_policy" {
  name   = "charalarm-api-role-policy"
  policy = data.aws_iam_policy_document.api_lambda_function_role_policy_document.json
}

data "aws_iam_policy_document" "api_lambda_function_role_policy_document" {
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
      "arn:aws:logs:ap-northeast-1:${local.account_id}:log-group:/aws/lambda/${aws_lambda_function.api_lambda_function.function_name}:*"
    ]
  }

  statement {
    sid    = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:*",
    ]
    resources = ["*"]
  }

  # 会話用 LLM キー等を実行時に Parameter Store から解決するための権限
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:ap-northeast-1:${local.account_id}:parameter${var.openai_api_key_ssm_parameter_name}"
    ]
  }

  # SecureString(既定の aws/ssm キー)を復号するための権限
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      data.aws_kms_alias.ssm.target_key_arn
    ]
  }
}

# SecureString の復号に使う AWS 管理 KMS キー
data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

resource "aws_iam_role_policy_attachment" "api_lambda_function_role_policy_attachment" {
  role       = aws_iam_role.api_lambda_function_role.name
  policy_arn = aws_iam_policy.api_lambda_function_role_policy.arn
}
