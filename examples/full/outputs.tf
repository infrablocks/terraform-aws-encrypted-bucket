output "kms_key_arn" {
  value = aws_kms_key.encryption_key.arn
}

output "access_log_bucket_arn" {
  value = aws_s3_bucket.access_log_bucket.arn
}

output "access_log_bucket_name" {
  value = aws_s3_bucket.access_log_bucket.id
}

output "bucket_name" {
  value = module.encrypted_bucket.bucket_name
}

output "bucket_arn" {
  value = module.encrypted_bucket.bucket_arn
}
