locals {
  sse_algorithm = var.kms_key_arn == "" ? "AES256" : "aws:kms"
  kms_master_key_id = var.kms_key_arn == "" ? null : var.kms_key_arn

  deny_unencrypted_object_uploads_fragment = templatefile(
    "${path.module}/policy-fragments/deny-unencrypted-object-uploads.json.tpl",
    {
      bucket_name = var.bucket_name
      sse_algorithm = local.sse_algorithm
    }
  )

  deny_unencrypted_inflight_operations_fragment = templatefile(
    "${path.module}/policy-fragments/deny-unencrypted-inflight-operations.json.tpl",
    { bucket_name = var.bucket_name }
  )

  encrypted_bucket_policy = templatefile(
    "${path.module}/policies/bucket-policy.json.tpl",
    {
      bucket_name = var.bucket_name
      deny_unencrypted_object_upload_fragment = local.deny_unencrypted_object_uploads_fragment
      deny_unencrypted_inflight_operations_fragment = local.deny_unencrypted_inflight_operations_fragment
    }
  )
}

resource "aws_s3_bucket" "access_log_bucket" {
  bucket = "${var.bucket_name}-access-log"
  acl    = "log-delivery-write"
  count = var.enable_access_logging == "yes" ? 1 : 0

  versioning {
    enabled = false
  }

  dynamic "server_side_encryption_configuration" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.kms_key_arn
          sse_algorithm = "aws:kms"
        }
        bucket_key_enabled = var.bucket_key_enabled
      }
    }
  }

  tags = merge({
    Name = var.bucket_name
  }, var.tags)
}

resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = var.bucket_name

  acl = var.acl

  force_destroy = var.allow_destroy_when_objects_present == "yes"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = local.kms_master_key_id
        sse_algorithm = local.sse_algorithm
      }
      bucket_key_enabled = var.bucket_key_enabled
    }
  }

  dynamic logging {
    for_each = var.enable_access_logging == "yes" ? [1] : []
    content {
      target_bucket = aws_s3_bucket.access_log_bucket[0].id
      target_prefix = "log/"
    }
  }

  versioning {
    enabled = true
    mfa_delete = var.mfa_delete
  }

  tags = merge({
    Name = var.bucket_name
  }, var.tags)
}

data "aws_iam_policy_document" "encrypted_bucket_policy_document" {
  source_json = var.source_policy_json
  override_json = local.encrypted_bucket_policy
}

resource "aws_s3_bucket_policy" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  policy = data.aws_iam_policy_document.encrypted_bucket_policy_document.json
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

  block_public_acls = var.public_access_block.block_public_acls
  block_public_policy = var.public_access_block.block_public_policy
  ignore_public_acls = var.public_access_block.ignore_public_acls
  restrict_public_buckets = var.public_access_block.restrict_public_buckets
}
