##################################################
# /push-token/ios/push
##################################################
resource "aws_api_gateway_resource" "push_token_ios_push_resource" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id
  parent_id   = aws_api_gateway_resource.push_token_ios_resource.id
  path_part   = "push"
}
