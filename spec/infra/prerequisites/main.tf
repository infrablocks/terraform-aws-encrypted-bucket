resource "aws_kms_key" "test_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "access_log_bucket" {
  bucket = var.access_log_bucket_name
}
