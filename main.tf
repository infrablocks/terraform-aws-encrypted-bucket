locals {
  sse_s3_algorithm  = "AES256"
  sse_kms_algorithm = "aws:kms"

  sse_algorithm     = local.kms_key_arn == "" ? local.sse_s3_algorithm : local.sse_kms_algorithm
  kms_master_key_id = local.kms_key_arn == "" ? null : local.kms_key_arn
}

// TODO: don't create these data resources if not used
data "aws_iam_policy_document" "deny_un_encrypted_inflight_operations" {
  statement {
    sid       = "DenyUnEncryptedInflightOperations"
    effect    = "Deny"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    actions   = ["s3:*"]

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
  statement {
    sid       = "DenyEncryptionUsingIncorrectAlgorithm"
    effect    = "Deny"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    actions   = ["s3:PutObject"]

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
  statement {
    sid       = "DenyEncryptionUsingIncorrectKey"
    effect    = "Deny"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    actions   = ["s3:PutObject"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEqualsIfExists"
      values   = [local.kms_key_arn]
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
    }
  }
}

resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = var.bucket_name

  force_destroy       = local.allow_destroy_when_objects_present
  object_lock_enabled = local.enable_object_lock

  tags = merge({
    Name = var.bucket_name
  }, local.tags)
}

resource "aws_s3_bucket_ownership_controls" "encrypted_bucket_ownership" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  acl    = local.acl

  depends_on = [aws_s3_bucket_ownership_controls.encrypted_bucket_ownership]
}

resource "aws_s3_bucket_logging" "encrypted_bucket" {
  count = local.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.encrypted_bucket.id

  target_bucket = local.access_log_bucket_name
  target_prefix = local.access_log_object_key_prefix
}

resource "aws_s3_bucket_versioning" "encrypted_bucket" {
  count = (
  local.enable_versioning
  || local.enable_mfa_delete
  ? 1 : 0
  )

  bucket = aws_s3_bucket.encrypted_bucket.id

  versioning_configuration {
    status     = local.enable_versioning ? "Enabled" : "Disabled"
    mfa_delete = local.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_master_key_id
      sse_algorithm     = local.sse_algorithm
    }
    bucket_key_enabled = local.enable_bucket_key
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count = (
  local.public_access_block.block_public_acls
  || local.public_access_block.block_public_policy
  || local.public_access_block.ignore_public_acls
  || local.public_access_block.restrict_public_buckets
  ? 1 : 0
  )

  bucket = aws_s3_bucket.encrypted_bucket.id

  block_public_acls       = local.public_access_block.block_public_acls
  block_public_policy     = local.public_access_block.block_public_policy
  ignore_public_acls      = local.public_access_block.ignore_public_acls
  restrict_public_buckets = local.public_access_block.restrict_public_buckets
}

data "aws_iam_policy_document" "encrypted_bucket_policy_document" {
  source_policy_documents = compact(
    [
      local.include_deny_unencrypted_inflight_operations_statement
      ? data.aws_iam_policy_document.deny_un_encrypted_inflight_operations.json
      : "",
      local.include_deny_encryption_using_incorrect_algorithm_statement
      ? data.aws_iam_policy_document.deny_encryption_using_incorrect_algorithm.json
      : "",
      local.include_deny_encryption_using_incorrect_key_statement && local.sse_algorithm == local.sse_kms_algorithm
      ? data.aws_iam_policy_document.deny_encryption_using_incorrect_key.json
      : "",
      local.source_policy_document != ""
      ? local.source_policy_document
      : ""
    ]
  )
}

resource "aws_s3_bucket_policy" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  policy = data.aws_iam_policy_document.encrypted_bucket_policy_document.json
}

resource "aws_s3_bucket_object_lock_configuration" "encrypted_bucket" {
  count = local.enable_object_lock && local.object_lock_configuration != null  ? 1 : 0

  bucket = aws_s3_bucket.encrypted_bucket.bucket

  rule {
    default_retention {
      mode  = local.object_lock_configuration.mode
      days  = try(local.object_lock_configuration.days, null)
      years = try(local.object_lock_configuration.years, null)
    }
  }
}
