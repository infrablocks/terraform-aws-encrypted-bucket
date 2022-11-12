resource "aws_kms_key" "encryption_key" {
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "access_log_bucket" {
  bucket = var.access_log_bucket_name
}

data "aws_iam_policy_document" "additional_statement" {
  statement {
    sid = "TestPolicy"
    effect = "Deny"

    actions = ["s3:*"]
    resources = ["arn:aws:s3:::${var.encrypted_bucket_name}/*"]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      variable = "aws:SourceIp"
      test = "IpAddress"
      values = ["8.8.8.8/32"]
    }
  }
}
