resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = var.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id      = var.rest_api_id
  resource_id      = var.resource_id
  http_method      = aws_api_gateway_method.api_gateway_method.http_method
  type             = "AWS_PROXY"
  content_handling = "CONVERT_TO_TEXT"
  # 原因は不明だが、POSTにしないとGETにしたときにエラーになる
  integration_http_method = "POST"
  uri                     = var.lambda_uri
  cache_key_parameters    = []
  request_parameters      = {}
  request_templates       = {}
}

resource "aws_api_gateway_method_response" "api_gateway_method_response" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.api_gateway_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "api_gateway_integration_response" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.api_gateway_method.http_method
  status_code = aws_api_gateway_method_response.api_gateway_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.api_gateway_integration
  ]
}
