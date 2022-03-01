module "encrypted_bucket" {
  # This makes absolutely no sense. I think there's a bug in terraform.
  source = "./../../../../../../../"

  bucket_name = var.bucket_name

  bucket_policy_template = var.bucket_policy_template
  source_policy_json = var.source_policy_json

  acl = var.acl

  tags = var.tags

  kms_key_arn = var.kms_key_arn

  access_log_bucket_name = var.access_log_bucket_name
  access_log_object_key_prefix = var.access_log_object_key_prefix

  public_access_block = var.public_access_block

  mfa_delete = var.mfa_delete
  enable_mfa_delete = var.enable_mfa_delete
  enable_versioning = var.enable_versioning
  enable_access_logging = var.enable_access_logging
  enable_bucket_key = var.enable_bucket_key
  allow_destroy_when_objects_present = var.allow_destroy_when_objects_present
}
