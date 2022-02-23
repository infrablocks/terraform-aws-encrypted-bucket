variable "region" {}
variable "bucket_name" {}
variable "mfa_delete" {}
variable "enable_access_logging" {}

variable "acl" {}

variable "include_source_policy_json" {}

variable "allow_destroy_when_objects_present" {}

variable "kms_key_arn" {
  default = null
}

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
