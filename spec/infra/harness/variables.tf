variable "region" {}

variable "bucket_name" {}

variable "source_policy_document" {}

variable "acl" {}

variable "tags" {
  type = map(string)
}

variable "kms_key_arn" {}

variable "access_log_bucket_name" {}
variable "access_log_object_key_prefix" {}

variable "public_access_block" {
  type = object({
    block_public_acls = bool
    block_public_policy = bool
    ignore_public_acls = bool
    restrict_public_buckets = bool
  })
  default = {
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
  }
}

variable "include_deny_unencrypted_inflight_operations_statement" {
  type = bool
}
variable "include_deny_encryption_using_incorrect_algorithm_statement" {
  type = bool
}
variable "include_deny_encryption_using_incorrect_key_statement" {
  type = bool
}

variable "enable_mfa_delete" {
  type = bool
}
variable "enable_versioning" {
  type = bool
}
variable "enable_access_logging" {
  type = bool
}
variable "enable_bucket_key" {
  type = bool
}
variable "allow_destroy_when_objects_present" {
  type = bool
}
