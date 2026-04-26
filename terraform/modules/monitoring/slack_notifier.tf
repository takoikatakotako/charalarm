data "archive_file" "slack_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambda/slack_notifier.py"
  output_path = "${path.module}/.build/slack_notifier.zip"
}

resource "aws_iam_role" "slack_notifier" {
  name               = "${var.name_prefix}-slack-notifier-role"
  assume_role_policy = data.aws_iam_policy_document.slack_notifier_assume.json
}

data "aws_iam_policy_document" "slack_notifier_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "slack_notifier" {
  name   = "${var.name_prefix}-slack-notifier-policy"
  policy = data.aws_iam_policy_document.slack_notifier.json
}

data "aws_iam_policy_document" "slack_notifier" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.name_prefix}-slack-notifier:*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter${var.slack_webhook_ssm_parameter_name}"]
  }
}

resource "aws_iam_role_policy_attachment" "slack_notifier" {
  role       = aws_iam_role.slack_notifier.name
  policy_arn = aws_iam_policy.slack_notifier.arn
}

resource "aws_cloudwatch_log_group" "slack_notifier" {
  name              = "/aws/lambda/${var.name_prefix}-slack-notifier"
  retention_in_days = 30
}

resource "aws_lambda_function" "slack_notifier" {
  function_name    = "${var.name_prefix}-slack-notifier"
  role             = aws_iam_role.slack_notifier.arn
  filename         = data.archive_file.slack_notifier.output_path
  source_code_hash = data.archive_file.slack_notifier.output_base64sha256
  handler          = "slack_notifier.lambda_handler"
  runtime          = "python3.12"
  architectures    = ["arm64"]
  timeout          = 10

  environment {
    variables = {
      WEBHOOK_SSM_PARAM = var.slack_webhook_ssm_parameter_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.slack_notifier]
}
