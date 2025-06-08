##################################################
# /user/info
##################################################
resource "aws_api_gateway_resource" "user_info_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_resource.user_resource.id
  path_part   = "info"
}

##################################################
# Lambda
##################################################
module "user_info_post_lambda_function" {
  source                    = "./lambda_function"
  function_name             = "user-info-post-function"
  role                      = aws_iam_role.api_gateway_lambda_role.arn
  s3_bucket                 = local.application_bucket_s3_url
  s3_key                    = "${var.application_version}/user_info.zip"
  execution_arn             = aws_api_gateway_rest_api.charalarm_rest_api.execution_arn
  method                    = "POST"
  path                      = "/user/info"
  environment_variables     = local.variables
  datadog_log_forwarder_arn = var.datadog_log_forwarder_arn
}

##################################################
# Method
##################################################
module "user_info_post_method" {
  source      = "./method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.user_info_resource.id
  http_method = "POST"
  lambda_uri  = module.user_info_post_lambda_function.invoke_arn
}

module "user_info_options_method" {
  source      = "./options_method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.user_info_resource.id
}

