
resource "aws_iam_role" "api_lambda_function_role" {
  name               = "charalarm-api-role-3j8iori2"
  path               = "/service-role/"
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
  name   = "AWSLambdaBasicExecutionRole-f9771750-cdd4-4969-93e6-4c3bd08680a0"
  policy = data.aws_iam_policy_document.api_lambda_function_role_policy_document.json
   path             = "/service-role/"
}

data "aws_iam_policy_document" "api_lambda_function_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = ["arn:aws:logs:ap-northeast-1:039612872248:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    resources = [
      "arn:aws:logs:ap-northeast-1:039612872248:log-group:/aws/lambda/charalarm-api:*"
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

}


resource "aws_iam_role_policy_attachment" "api_lambda_function_role_policy_attachment" {
  role       = aws_iam_role.api_lambda_function_role.name
  policy_arn = aws_iam_policy.api_lambda_function_role_policy.arn
}
