##################################################
# /chara/list
##################################################
resource "aws_api_gateway_resource" "chara_list_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_resource.chara_resource.id
  path_part   = "list"
}

##################################################
# Lambda
##################################################
module "chara_list_post_lambda_function" {
  source                    = "./lambda_function"
  function_name             = "chara-list-get-function"
  role                      = aws_iam_role.api_gateway_lambda_role.arn
  s3_bucket                 = local.application_bucket_s3_url
  s3_key                    = "/${var.application_version}/chara_list.zip"
  execution_arn             = aws_api_gateway_rest_api.charalarm_rest_api.execution_arn
  method                    = "GET"
  path                      = "/chara/list"
  environment_variables     = local.variables
  datadog_log_forwarder_arn = var.datadog_log_forwarder_arn
}

##################################################
# Method
##################################################
module "chara_list_get_method" {
  source      = "./method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.chara_list_resource.id
  http_method = "GET"
  lambda_uri  = module.chara_list_post_lambda_function.invoke_arn
}

module "chara_list_options_method" {
  source      = "./options_method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.chara_list_resource.id
}
