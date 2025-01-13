##################################################
# /chara/id/{id}
##################################################
resource "aws_api_gateway_resource" "chara_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_resource.chara_resource.id
  path_part   = "id"
}

resource "aws_api_gateway_resource" "chara_id_value_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_resource.chara_id_resource.id
  path_part   = "{id}"
}

##################################################
# Lambda
##################################################
module "chara_id_get_lambda_function" {
  source                    = "./lambda_function"
  function_name             = "chara-id-get-function"
  role                      = aws_iam_role.api_gateway_lambda_role.arn
  s3_bucket                 = local.application_bucket_s3_url
  s3_key                    = "/${var.application_version}/chara_id.zip"
  execution_arn             = aws_api_gateway_rest_api.charalarm_rest_api.execution_arn
  method                    = "GET"
  path                      = "/chara/id/{id}"
  environment_variables     = local.variables
  datadog_log_forwarder_arn = var.datadog_log_forwarder_arn
}

##################################################
# Method
##################################################
module "chara_id_get_method" {
  source      = "./method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.chara_id_value_resource.id
  http_method = "GET"
  lambda_uri  = module.chara_id_get_lambda_function.invoke_arn
}

module "chara_id_options_method" {
  source      = "./options_method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.chara_id_value_resource.id
}
