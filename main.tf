locals {
  sse_s3_algorithm  = "AES256"
  sse_kms_algorithm = "aws:kms"

  sse_algorithm     = var.kms_key_arn == "" ? local.sse_s3_algorithm : local.sse_kms_algorithm
  kms_master_key_id = var.kms_key_arn == "" ? null : var.kms_key_arn

  deny_encryption_using_incorrect_algorithm_fragment = templatefile(
    "${path.module}/policy-fragments/deny-encryption-using-incorrect-algorithm.json.tpl",
    {
      bucket_name   = var.bucket_name
      sse_algorithm = local.sse_algorithm
    }
  )

  deny_encryption_using_incorrect_key_fragment = (local.sse_algorithm == local.sse_kms_algorithm) ? templatefile(
    "${path.module}/policy-fragments/deny-encryption-using-incorrect-key.json.tpl",
    {
      bucket_name = var.bucket_name
      kms_key_arn = var.kms_key_arn
    }
  ) : ""

  deny_unencrypted_inflight_operations_fragment = templatefile(
    "${path.module}/policy-fragments/deny-unencrypted-inflight-operations.json.tpl",
    {
      bucket_name = var.bucket_name
    }
  )

  bucket_policy = templatefile(
    "${path.module}/policies/bucket-policy.json.tpl",
    {
      bucket_name                                        = var.bucket_name
      deny_encryption_using_incorrect_algorithm_fragment = local.deny_encryption_using_incorrect_algorithm_fragment
      deny_encryption_using_incorrect_key_fragment       = local.deny_encryption_using_incorrect_key_fragment
      deny_unencrypted_inflight_operations_fragment      = local.deny_unencrypted_inflight_operations_fragment
    })
}

resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = var.bucket_name

  acl = var.acl

  force_destroy = var.allow_destroy_when_objects_present

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = local.kms_master_key_id
        sse_algorithm     = local.sse_algorithm
      }
      bucket_key_enabled = var.enable_bucket_key
    }
  }

  dynamic logging {
    for_each = var.enable_access_logging ? toset(["logging"]) : toset([])
    content {
      target_bucket = var.access_log_bucket_name
      target_prefix = var.access_log_object_key_prefix
    }
  }

  versioning {
    enabled    = var.enable_versioning
    mfa_delete = var.enable_mfa_delete
  }

  tags = merge({
    Name = var.bucket_name
  }, var.tags)
}

data "aws_iam_policy_document" "encrypted_bucket_policy_document" {
  source_json   = var.source_policy_json
  override_json = local.bucket_policy
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

  block_public_acls       = var.public_access_block.block_public_acls
  block_public_policy     = var.public_access_block.block_public_policy
  ignore_public_acls      = var.public_access_block.ignore_public_acls
  restrict_public_buckets = var.public_access_block.restrict_public_buckets
}
