module "encrypted_bucket" {
  # This makes absolutely no sense. I think there's a bug in terraform.
  source = "./../../../../../../../"

  bucket_name = var.bucket_name

  source_policy_document = var.source_policy_document

  acl = var.acl

  tags = var.tags

  kms_key_arn = var.kms_key_arn

  access_log_bucket_name = var.access_log_bucket_name
  access_log_object_key_prefix = var.access_log_object_key_prefix

  public_access_block = var.public_access_block

  include_deny_unencrypted_inflight_operations_statement = var.include_deny_unencrypted_inflight_operations_statement
  include_deny_encryption_using_incorrect_algorithm_statement = var.include_deny_encryption_using_incorrect_algorithm_statement
  include_deny_encryption_using_incorrect_key_statement = var.include_deny_encryption_using_incorrect_key_statement

  enable_mfa_delete = var.enable_mfa_delete
  enable_versioning = var.enable_versioning
  enable_access_logging = var.enable_access_logging
  enable_bucket_key = var.enable_bucket_key
  allow_destroy_when_objects_present = var.allow_destroy_when_objects_present
}
