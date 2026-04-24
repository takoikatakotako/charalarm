output "bucket_name" {
  value = aws_s3_bucket.admin_frontend.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.admin.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.admin.domain_name
}
