locals {
  # default for cases when `null` value provided, meaning "use default"
  source_policy_document       = var.source_policy_document == null ? "" : var.source_policy_document
  acl                          = var.acl == null ? "private" : var.acl
  tags                         = var.tags == null ? {} : var.tags
  kms_key_arn                  = var.kms_key_arn == null ? "" : var.kms_key_arn
  access_log_bucket_name       = var.access_log_bucket_name == null ? "" : var.access_log_bucket_name
  access_log_object_key_prefix = var.access_log_object_key_prefix == null ? "" : var.access_log_object_key_prefix
  public_access_block          = var.public_access_block == null ? {
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  } : var.public_access_block
  include_deny_unencrypted_inflight_operations_statement      = var.include_deny_unencrypted_inflight_operations_statement == null ? true : var.include_deny_unencrypted_inflight_operations_statement
  include_deny_encryption_using_incorrect_algorithm_statement = var.include_deny_encryption_using_incorrect_algorithm_statement == null ? true : var.include_deny_encryption_using_incorrect_algorithm_statement
  include_deny_encryption_using_incorrect_key_statement       = var.include_deny_encryption_using_incorrect_key_statement == null ? true : var.include_deny_encryption_using_incorrect_key_statement
  enable_mfa_delete                                           = var.enable_mfa_delete == null ? false : var.enable_mfa_delete
  enable_versioning                                           = var.enable_versioning == null ? true : var.enable_versioning
  enable_access_logging                                       = var.enable_access_logging == null ? false : var.enable_access_logging
  enable_bucket_key                                           = var.enable_bucket_key == null ? false : var.enable_bucket_key
  enable_object_lock                                          = var.enable_object_lock == null ? false : var.enable_object_lock
  allow_destroy_when_objects_present                          = var.allow_destroy_when_objects_present == null ? false : var.allow_destroy_when_objects_present
  object_lock_configuration                                   = var.object_lock_configuration
}
