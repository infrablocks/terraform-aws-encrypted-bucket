variable "region" {}

variable "bucket_name" {}

variable "source_policy_document" {
  default = null
}

variable "acl" {
  default = null
}

variable "tags" {
  type    = map(string)
  default = null
}

variable "kms_key_arn" {
  default = null
}

variable "access_log_bucket_name" {
  default = null
}
variable "access_log_object_key_prefix" {
  default = null
}

variable "public_access_block" {
  type = object({
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
  })
  default = null
}

variable "include_deny_unencrypted_inflight_operations_statement" {
  type    = bool
  default = null
}
variable "include_deny_encryption_using_incorrect_algorithm_statement" {
  type    = bool
  default = null
}
variable "include_deny_encryption_using_incorrect_key_statement" {
  type    = bool
  default = null
}

variable "enable_mfa_delete" {
  type    = bool
  default = null
}
variable "enable_versioning" {
  type    = bool
  default = null
}
variable "enable_access_logging" {
  type    = bool
  default = null
}
variable "enable_bucket_key" {
  type    = bool
  default = null
}
variable "allow_destroy_when_objects_present" {
  type    = bool
  default = null
}
