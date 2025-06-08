##################################################
# API Gateway
##################################################
resource "aws_api_gateway_rest_api" "charalarm_rest_api" {
  name = "charalarm-api"
}

resource "aws_api_gateway_deployment" "charalarm_deployment" {
  rest_api_id = aws_api_gateway_rest_api.charalarm_rest_api.id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      triggers
    ]
  }
}

resource "aws_api_gateway_stage" "charalarm_stage" {
  deployment_id = aws_api_gateway_deployment.charalarm_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.charalarm_rest_api.id
  stage_name    = "production"
  tags          = {}
  variables     = {}
  lifecycle {
    ignore_changes = [
      deployment_id # deploy は何回も作り直されるため
    ]
  }
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  regional_certificate_arn = var.acm_certificate_arn
  domain_name              = var.domain
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api_gateway_base_path_mapping" {
  api_id      = aws_api_gateway_rest_api.charalarm_rest_api.id
  stage_name  = aws_api_gateway_stage.charalarm_stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name.domain_name
}

##############################################################
# Route53
##############################################################
resource "aws_route53_record" "route53_record" {
  zone_id = var.route53_zone_id
  name    = var.domain
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api_gateway_domain_name.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name.regional_zone_id
  }
}


##############################################################
# S3
##############################################################
resource "aws_s3_bucket" "application_bucket" {
  bucket = var.application_bucket_name
}
