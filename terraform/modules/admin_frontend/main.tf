data "aws_ssm_parameter" "basic_auth_user" {
  name = var.basic_auth_user_ssm_parameter_name
}

data "aws_ssm_parameter" "basic_auth_password" {
  name = var.basic_auth_password_ssm_parameter_name
}

locals {
  api_origin_domain      = trimsuffix(trimprefix(var.admin_api_function_url, "https://"), "/")
  basic_auth_credentials = base64encode("${data.aws_ssm_parameter.basic_auth_user.value}:${data.aws_ssm_parameter.basic_auth_password.value}")
  cloudfront_zone_id     = "Z2FDTNDATAQYW2"
}

##############################################################
# S3 (frontend bucket)
##############################################################
resource "aws_s3_bucket" "admin_frontend" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "admin_frontend" {
  bucket                  = aws_s3_bucket.admin_frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################################################
# OAC (S3 と Lambda Function URL)
##############################################################
resource "aws_cloudfront_origin_access_control" "admin_frontend" {
  name                              = var.bucket_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "admin_api" {
  name                              = "${var.name_prefix}-admin-api"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

##############################################################
# CloudFront Functions (Basic 認証 + URI 書き換え)
##############################################################
resource "aws_cloudfront_function" "admin_spa_rewrite" {
  name    = "${var.name_prefix}-admin-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOF
    var CREDENTIALS = '${local.basic_auth_credentials}';
    function handler(event) {
      var request = event.request;
      var headers = request.headers;
      var auth = headers.authorization;
      if (!auth || auth.value !== 'Basic ' + CREDENTIALS) {
        return {
          statusCode: 401,
          statusDescription: 'Unauthorized',
          headers: { 'www-authenticate': { value: 'Basic realm="Admin"' } },
        };
      }
      var uri = request.uri;
      if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
      } else if (!uri.includes('.')) {
        var segments = uri.split('/').filter(function(s) { return s; });
        if (segments.length > 1) {
          request.uri = '/' + segments[0] + '/index.html';
        } else {
          request.uri = uri + '/index.html';
        }
      }
      return request;
    }
  EOF
}

resource "aws_cloudfront_function" "admin_api_auth_rewrite" {
  name    = "${var.name_prefix}-admin-api-auth-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOF
    var CREDENTIALS = '${local.basic_auth_credentials}';
    function handler(event) {
      var request = event.request;
      var headers = request.headers;
      var auth = headers.authorization;
      if (!auth || auth.value !== 'Basic ' + CREDENTIALS) {
        return {
          statusCode: 401,
          statusDescription: 'Unauthorized',
          headers: { 'www-authenticate': { value: 'Basic realm="Admin"' } },
        };
      }
      // OAC SigV4 署名と競合するため Basic 認証通過後に Authorization を削除
      delete request.headers.authorization;
      request.uri = request.uri.replace(/^\/api/, '');
      if (request.uri === '') {
        request.uri = '/';
      }
      return request;
    }
  EOF
}

##############################################################
# CloudFront Distribution
##############################################################
resource "aws_cloudfront_distribution" "admin" {
  origin {
    domain_name              = aws_s3_bucket.admin_frontend.bucket_regional_domain_name
    origin_id                = "s3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.admin_frontend.id
  }

  origin {
    domain_name              = local.api_origin_domain
    origin_id                = "lambda-admin-api"
    origin_access_control_id = aws_cloudfront_origin_access_control.admin_api.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Admin frontend + API for ${var.name_prefix}"
  default_root_object = "index.html"
  aliases             = [var.domain]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.admin_spa_rewrite.arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "lambda-admin-api"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.admin_api_auth_rewrite.arn
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

##############################################################
# Route53
##############################################################
resource "aws_route53_record" "admin" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.admin.domain_name
    zone_id                = local.cloudfront_zone_id
  }
}

##############################################################
# Lambda Permission (CloudFront から OAC で呼び出すため)
##############################################################
resource "aws_lambda_permission" "admin_cloudfront" {
  statement_id           = "AllowCloudFrontInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = var.admin_api_function_name
  principal              = "cloudfront.amazonaws.com"
  function_url_auth_type = "AWS_IAM"
  source_arn             = aws_cloudfront_distribution.admin.arn
}

##############################################################
# S3 Bucket Policy (CloudFront OAC から GetObject 許可)
##############################################################
resource "aws_s3_bucket_policy" "admin_frontend" {
  bucket = aws_s3_bucket.admin_frontend.id
  policy = data.aws_iam_policy_document.admin_frontend_s3_access.json
}

data "aws_iam_policy_document" "admin_frontend_s3_access" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.admin_frontend.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.admin.arn]
    }
  }
}
