locals {
  sse_s3_algorithm  = "AES256"
  sse_kms_algorithm = "aws:kms"

  sse_algorithm     = var.kms_key_arn == "" ? local.sse_s3_algorithm : local.sse_kms_algorithm
  kms_master_key_id = var.kms_key_arn == "" ? null : var.kms_key_arn
}

data "aws_iam_policy_document" "deny_un_encrypted_inflight_operations" {
  count = var.include_deny_unencrypted_inflight_operations_statement ? 1 : 0

  statement {
    sid = "DenyUnEncryptedInflightOperations"
    effect = "Deny"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    actions = ["s3:*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

data "aws_iam_policy_document" "deny_encryption_using_incorrect_algorithm" {
  count = var.include_deny_encryption_using_incorrect_algorithm_statement ? 1 : 0

  statement {
    sid = "DenyEncryptionUsingIncorrectAlgorithm"
    effect = "Deny"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    actions = ["s3:PutObject"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Null"
      values   = ["false"]
      variable = "s3:x-amz-server-side-encryption"
    }

    condition {
      test     = "StringNotEquals"
      values   = [local.sse_algorithm]
      variable = "s3:x-amz-server-side-encryption"
    }
  }
}

data "aws_iam_policy_document" "deny_encryption_using_incorrect_key" {
  count = var.include_deny_encryption_using_incorrect_key_statement && local.sse_algorithm == local.sse_kms_algorithm ? 1 : 0

  statement {
    sid = "DenyEncryptionUsingIncorrectKey"
    effect = "Deny"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    actions = ["s3:PutObject"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEqualsIfExists"
      values   = [local.kms_master_key_id]
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
    }
  }
}

resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = var.bucket_name

  force_destroy = var.allow_destroy_when_objects_present

  tags = merge({
    Name = var.bucket_name
  }, var.tags)
}

resource "aws_s3_bucket_acl" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  acl    = var.acl
}

resource "aws_s3_bucket_logging" "encrypted_bucket" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.encrypted_bucket.id

  target_bucket = var.access_log_bucket_name
  target_prefix = var.access_log_object_key_prefix
}

resource "aws_s3_bucket_versioning" "encrypted_bucket" {
  count = (
    var.enable_versioning
      || var.enable_mfa_delete
    ? 1 : 0
  )

  bucket = aws_s3_bucket.encrypted_bucket.id

  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Disabled"
    mfa_delete = var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_master_key_id
      sse_algorithm     = local.sse_algorithm
    }
    bucket_key_enabled = var.enable_bucket_key
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count = (
    var.public_access_block.block_public_acls
      || var.public_access_block.block_public_policy
      || var.public_access_block.ignore_public_acls
      || var.public_access_block.restrict_public_buckets
    ? 1 : 0
  )

  bucket = aws_s3_bucket.encrypted_bucket.id

  block_public_acls       = var.public_access_block.block_public_acls
  block_public_policy     = var.public_access_block.block_public_policy
  ignore_public_acls      = var.public_access_block.ignore_public_acls
  restrict_public_buckets = var.public_access_block.restrict_public_buckets
}

data "aws_iam_policy_document" "encrypted_bucket_policy_document" {
  source_policy_documents = compact(
    [
      var.include_deny_unencrypted_inflight_operations_statement
        ? data.aws_iam_policy_document.deny_un_encrypted_inflight_operations[0].json
        : "",
      var.include_deny_encryption_using_incorrect_algorithm_statement
        ? data.aws_iam_policy_document.deny_encryption_using_incorrect_algorithm[0].json
        : "",
      var.include_deny_encryption_using_incorrect_key_statement && local.sse_algorithm == local.sse_kms_algorithm
        ? data.aws_iam_policy_document.deny_encryption_using_incorrect_key[0].json
        : "",
      var.source_policy_document != ""
        ? var.source_policy_document
        : ""
    ]
  )
}

resource "aws_s3_bucket_policy" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  policy = data.aws_iam_policy_document.encrypted_bucket_policy_document.json
}
