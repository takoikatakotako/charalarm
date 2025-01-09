##################################################
# Lambdaにアタッチするためのロール
##################################################
resource "aws_iam_role" "worker_lambda_role" {
  name               = "worker-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.worker_lambda_role_assume_policy_document.json
}

data "aws_iam_policy_document" "worker_lambda_role_assume_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "worker_lambda_role_policy" {
  name   = "worker-lambda-role-policy"
  policy = data.aws_iam_policy_document.worker_lambda_role_iam_policy_document.json
}

data "aws_iam_policy_document" "worker_lambda_role_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "worker_lambda_role_policy_attachment" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = aws_iam_policy.worker_lambda_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_lambda_role_basic_execution_policy_attachment" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "worker_lambda_role_sqs_execution_policy_attachment" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "worker_lambda_role_sns_full_access_policy_attachment" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}
