# Lambda Function Edge Role
resource "aws_iam_role" "api_lambda_function_edge_role" {
  name               = "api-lambda-function-edge-role"
  assume_role_policy = data.aws_iam_policy_document.api_lambda_function_edge_role_assume_policy_document.json
}

data "aws_iam_policy_document" "api_lambda_function_edge_role_assume_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "api_lambda_function_edge_role_policy" {
  name   = "api-lambda-function-edge-role-policy"
  policy = data.aws_iam_policy_document.api_lambda_function_edge_role_policy_document.json
}

data "aws_iam_policy_document" "api_lambda_function_edge_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "api_lambda_function_edge_role_policy_attachment" {
  role       = aws_iam_role.api_lambda_function_edge_role.name
  policy_arn = aws_iam_policy.api_lambda_function_edge_role_policy.arn
}