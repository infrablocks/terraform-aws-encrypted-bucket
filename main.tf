locals {
  sse_s3_algorithm  = "AES256"
  sse_kms_algorithm = "aws:kms"

  sse_algorithm     = var.kms_key_arn == "" ? local.sse_s3_algorithm : local.sse_kms_algorithm
  kms_master_key_id = var.kms_key_arn == "" ? null : var.kms_key_arn

  enable_versioning                  = var.enable_versioning == "yes"
  enable_mfa_delete                  = var.enable_mfa_delete == "" ? var.mfa_delete == "true" : var.enable_mfa_delete == "yes"
  enable_access_logging              = var.enable_access_logging == "yes"
  enable_bucket_key                 = var.enable_bucket_key == "yes"
  allow_destroy_when_objects_present = var.allow_destroy_when_objects_present == "yes"

  deny_encryption_using_incorrect_algorithm_fragment = templatefile(
    "${path.module}/policy-fragments/deny-encryption-using-incorrect-algorithm.json.tpl",
    {
      bucket_name   = var.bucket_name
      sse_algorithm = local.sse_algorithm
    }
  )

  deny_encryption_using_incorrect_key_fragment = templatefile(
    "${path.module}/policy-fragments/deny-encryption-using-incorrect-key.json.tpl",
    {
      bucket_name = var.bucket_name
      kms_key_arn = var.kms_key_arn
    }
  )

  deny_unencrypted_inflight_operations_fragment = templatefile(
    "${path.module}/policy-fragments/deny-unencrypted-inflight-operations.json.tpl",
    {
      bucket_name = var.bucket_name
    }
  )
}

data "template_file" "encrypted_bucket_policy" {
  template = coalesce(var.bucket_policy_template, file("${path.module}/policies/bucket-policy.json.tpl"))

  vars = {
    bucket_name                                        = var.bucket_name
    deny_encryption_using_incorrect_algorithm_fragment = local.deny_encryption_using_incorrect_algorithm_fragment
    deny_encryption_using_incorrect_key_fragment       = local.sse_algorithm == local.sse_kms_algorithm ? local.deny_encryption_using_incorrect_key_fragment : ""
    deny_unencrypted_inflight_operations_fragment      = local.deny_unencrypted_inflight_operations_fragment
    # required for backwards compatibility
    deny_unencrypted_object_upload_fragment            = local.deny_encryption_using_incorrect_algorithm_fragment
  }
}

resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = var.bucket_name

  acl = var.acl

  force_destroy = local.allow_destroy_when_objects_present

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = local.kms_master_key_id
        sse_algorithm     = local.sse_algorithm
      }
      bucket_key_enabled = local.enable_bucket_key
    }
  }

  dynamic logging {
    for_each = local.enable_access_logging ? toset(["logging"]) : toset([])
    content {
      target_bucket = var.access_log_bucket_name
      target_prefix = var.access_log_object_key_prefix
    }
  }

  versioning {
    enabled    = local.enable_versioning
    mfa_delete = local.enable_mfa_delete
  }

  tags = merge({
    Name = var.bucket_name
  }, var.tags)
}

data "aws_iam_policy_document" "encrypted_bucket_policy_document" {
  source_json   = var.source_policy_json
  override_json = data.template_file.encrypted_bucket_policy.rendered
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
