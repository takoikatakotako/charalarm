##################################################
# /healthcheck
##################################################
resource "aws_api_gateway_resource" "healthcheck_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_rest_api.charalarm_rest_api.root_resource_id
  path_part   = "healthcheck"
}

##################################################
# Lambda
##################################################
module "healthcheck_get_lambda_function" {
  source                    = "./lambda_function"
  function_name             = "healthcheck-get-function"
  role                      = aws_iam_role.api_gateway_lambda_role.arn
  s3_bucket                 = local.application_bucket_s3_url
  s3_key                    = "/${var.application_version}/healthcheck.zip"
  execution_arn             = aws_api_gateway_rest_api.charalarm_rest_api.execution_arn
  method                    = "GET"
  path                      = "/healthcheck"
  environment_variables     = local.variables
  datadog_log_forwarder_arn = var.datadog_log_forwarder_arn
}

##################################################
# Method
##################################################
module "healthcheck_method" {
  source      = "./method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.healthcheck_resource.id
  http_method = "GET"
  lambda_uri  = module.healthcheck_get_lambda_function.invoke_arn
}

module "healthcheck_options_method" {
  source      = "./options_method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.healthcheck_resource.id
}
