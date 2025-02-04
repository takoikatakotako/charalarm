# API Lambda Function
resource "aws_lambda_function" "api_lambda_function" {
  function_name = "charalarm-api"
  role          = aws_iam_role.api_lambda_function_role.arn
  image_uri     = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-api:latest"
  package_type  = "Image"
  architectures = ["arm64"]
}

resource "aws_lambda_function_url" "api_lambda_function_url" {
  function_name      = aws_lambda_function.api_lambda_function.function_name
  authorization_type = "AWS_IAM"
}

resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowCloudFrontServicePrincipal"
  function_url_auth_type = "AWS_IAM"
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.api_lambda_function.function_name
  principal     = "cloudfront.amazonaws.com"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "api_cloudfront_distribution" {
  enabled = true
  is_ipv6_enabled                = true
  origin {
    domain_name              = "${aws_lambda_function_url.api_lambda_function_url.url_id}.lambda-url.ap-northeast-1.on.aws"
    origin_id                = "${aws_lambda_function_url.api_lambda_function_url.url_id}.lambda-url.ap-northeast-1.on.aws"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access_control.id

          custom_origin_config {
              http_port                = 80 
              https_port               = 443 
              origin_keepalive_timeout = 5
              origin_protocol_policy   = "https-only"
              origin_read_timeout      = 30 
              origin_ssl_protocols     = [
                  "TLSv1.2",
                ] 
            }
  }


  default_cache_behavior {
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    compress                 = true
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_lambda_function_url.api_lambda_function_url.url_id}.lambda-url.ap-northeast-1.on.aws"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access_control" {
  name                              = "charalarm-api"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
