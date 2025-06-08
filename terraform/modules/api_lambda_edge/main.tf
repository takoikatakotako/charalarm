
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
  }
}

# Lambda Edge Function
resource "aws_lambda_function" "api_lambda_edge_function" {
  publish       = true
  function_name = "api-lambda-edge-function"
  role          = aws_iam_role.api_lambda_function_edge_role.arn
  package_type  = "Zip"
  handler       = "lambda_function.lambda_handler"
  layers        = []
  architectures = ["x86_64"]
  runtime       = "python3.13"

  filename         = data.archive_file.lambda_edge_file.output_path
  source_code_hash = data.archive_file.lambda_edge_file.output_base64sha256
}

data "archive_file" "lambda_edge_file" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_edge_file"
  output_path = "${path.module}/lambda_edge_file.zip"
}


