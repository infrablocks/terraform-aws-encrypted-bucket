output "bucket_name" {
  description = "The name of the created bucket."
  value = aws_s3_bucket.encrypted_bucket.bucket
}
