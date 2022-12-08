variable "bucket_name" {
  description = "The name to use for the encrypted S3 bucket."
  type = string
}

variable "source_policy_document" {
  description = "A source policy for the bucket, additional statements to enable encryption will be added to the policy."
  type = string
  default = ""
}

variable "acl" {
  description = "The canned ACL to apply. Defaults to \"private\"."
  type = string
  default = "private"
}

variable "tags" {
  description = "A map of additional tags to set on the bucket."
  type = map(string)
  default = {}
}

variable "kms_key_arn" {
  description = "If provided, \"aws:kms\" encryption will be enforced using the KMS key with the provided ARN. By default, \"AES-256\" encryption is used."
  type = string
  default = ""
}

variable "access_log_bucket_name" {
  description = "The name of the bucket to use for access logging, required when enable_access_logging is \"yes\"."
  type = string
  default = ""
}

variable "access_log_object_key_prefix" {
  description = "The key prefix to use for log objects for access logging. Defaults to \"\"."
  type = string
  default = ""
}

variable "public_access_block" {
  description = "If provided, will configure block public access settings for the bucket."
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
  description = "Whether or not to include a bucket policy statement to deny unencrypted inflight operations. Defaults to `true`."
  type = bool
  default = true
}
variable "include_deny_encryption_using_incorrect_algorithm_statement" {
  description = "Whether or not to include a bucket policy statement to deny encryption using the incorrect algorithm. Defaults to `true`."
  type = bool
  default = true
}
variable "include_deny_encryption_using_incorrect_key_statement" {
  description = "Whether or not to include a bucket policy statement to deny encryption using the incorrect key. Defaults to `true`."
  type = bool
  default = true
}

variable "enable_mfa_delete" {
  description = "Whether or not to enable MFA delete on the bucket. Defaults to `false`."
  type = bool
  default = false
}

variable "enable_versioning" {
  description = "Whether or not to enable versioning on the bucket. Defaults to `true`."
  type = bool
  default = true
}

variable "enable_access_logging" {
  description = "Whether or not to enable access logging on the bucket. Defaults to `false`."
  type = bool
  default = false
}

variable "enable_bucket_key" {
  description = "Whether or not to use an Amazon S3 Bucket Key for SSE-KMS. Defaults to `false`."
  type = bool
  default = false
}

variable "enable_object_lock" {
  description = "Whether or not to enable object lock on the bucket. Defaults to `false`."
  type = bool
  default = false
}

variable "allow_destroy_when_objects_present" {
  description = "Whether or not to allow the bucket to be destroyed if it still contains objects. Defaults to `false`."
  type = bool
  default = false
}

variable "object_lock_configuration" {
  description = "If provided, will configure object lock configuration rule for the bucket."
  type        = object({
    mode  = string
    days  = number
    years = number
  })
  default = null
}

