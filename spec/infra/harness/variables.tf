variable "region" {}

variable "bucket_name" {}

variable "bucket_policy_template" {}
variable "source_policy_json" {}

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

variable "mfa_delete" {}
variable "enable_mfa_delete" {}
variable "enable_versioning" {}
variable "enable_access_logging" {}
variable "enable_bucket_key" {}
variable "allow_destroy_when_objects_present" {}
