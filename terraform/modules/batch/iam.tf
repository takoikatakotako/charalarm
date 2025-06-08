##################################################
# Lambdaにアタッチするためのロール
##################################################
resource "aws_iam_role" "batch_lambda_role" {
  name               = "batch-lambda-role"
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
  name   = "batch-lambda-role-policy"
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

resource "aws_iam_role_policy_attachment" "batch_lambda_role_policy_attachment" {
  role       = aws_iam_role.batch_lambda_role.name
  policy_arn = aws_iam_policy.batch_lambda_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "batch_lambda_role_basic_execution_policy_attachment" {
  role       = aws_iam_role.batch_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
