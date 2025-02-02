# API Lambda Function
resource "aws_lambda_function" "api_lambda_function" {
  function_name = "charalarm-api"
  role          = "arn:aws:iam::039612872248:role/service-role/charalarm-api-role-3j8iori2"
  image_uri     = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-api:latest"
  package_type  = "Image"
}

