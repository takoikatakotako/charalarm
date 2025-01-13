##################################################
# /alarm/add
##################################################
resource "aws_api_gateway_resource" "alarm_add_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_resource.alarm_resource.id
  path_part   = "add"
}

##################################################
# Lambda
##################################################
module "alarm_add_post_lambda_function" {
  source                    = "./lambda_function"
  function_name             = "alarm-add-post-function"
  role                      = aws_iam_role.api_gateway_lambda_role.arn
  s3_bucket                 = local.application_bucket_s3_url
  s3_key                    = "/${var.application_version}/alarm_add.zip"
  execution_arn             = aws_api_gateway_rest_api.charalarm_rest_api.execution_arn
  method                    = "POST"
  path                      = "/alarm/add"
  environment_variables     = local.variables
  datadog_log_forwarder_arn = var.datadog_log_forwarder_arn
}

##################################################
# Method
##################################################
module "alarm_add_post_method" {
  source      = "./method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.alarm_add_resource.id
  http_method = "POST"
  lambda_uri  = module.alarm_add_post_lambda_function.invoke_arn
}

module "alarm_add_options_method" {
  source      = "./options_method"
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  resource_id = aws_api_gateway_resource.alarm_add_resource.id
}

