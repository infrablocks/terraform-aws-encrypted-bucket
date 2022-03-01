variable "bucket_name" {
  description = "The name to use for the encrypted S3 bucket."
  type = string
}

variable "bucket_policy_template" {
  description = "A template for the policy to apply to the bucket. Deprecated - use source_policy_json instead."
  type = string
  default = ""
}
variable "source_policy_json" {
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

variable "mfa_delete" {
  description = "Whether or not to enable MFA delete on the bucket (\"true\" or \"false\"). Defaults to \"false\". Deprecated - use enable_mfa_delete instead."
  type = string
  default = "false"
}

variable "enable_mfa_delete" {
  description = "Whether or not to enable MFA delete on the bucket (\"yes\" or \"no\"). Defaults to \"no\"."
  type = string
  default = ""
}

variable "enable_versioning" {
  description = "Whether or not to enable versioning on the bucket (\"yes\" or \"no\"). Defaults to \"yes\"."
  type = string
  default = "yes"
}

variable "enable_access_logging" {
  description = "Whether or not to enable access logging on the bucket (\"yes\" or \"no\"). Defaults to \"no\"."
  type = string
  default = "no"
}

variable "enable_bucket_key" {
  description = "Whether or not to use an Amazon S3 Bucket Key for SSE-KMS. (\"yes\" or \"no\"). Defaults to \"no\"."
  type = string
  default = "no"
}

variable "allow_destroy_when_objects_present" {
  description = "Whether or not to allow the bucket to be destroyed if it still contains objects (\"yes\" or \"no\"). Defaults to \"no\"."
  type = string
  default = "no"
}
