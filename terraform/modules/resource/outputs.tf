output "bucket_name" {
  value = aws_s3_bucket.s3_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.s3_bucket.arn
}

output "distribution_id" {
  value = aws_cloudfront_distribution.charalarm_cloudfront_distribution.id
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.charalarm_cloudfront_distribution.arn
}
