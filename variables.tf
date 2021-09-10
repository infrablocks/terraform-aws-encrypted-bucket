variable "bucket_name" {
  description = "The name to use for the encrypted S3 bucket."
}

variable "bucket_policy_template" {
  description = "A template for the policy to apply to the bucket."
  default = ""
}
variable "source_policy_json" {
  description = "A source policy for the bucket, additional statements to enable encryption will be added to the policy"
  default = ""
}

variable "acl" {
  description = "The canned ACL to apply. Defaults to private."
  default = "private"
}

variable "tags" {
  description = "A map of additional tags to set on the bucket."
  type = map(string)
  default = {}
}

variable "mfa_delete" {
  description = "Enable MFA delete for either Change the versioning state of your bucket or Permanently delete an object version. Default is false."
  default = "false"
}

variable "allow_destroy_when_objects_present" {
  description = "Whether or not to allow the bucket to be destroyed if it still contains objects (\"yes\" or \"no\")."
  type = string
  default = "no"
}

variable "kms_key_arn" {
  description = "If provided, the given key will be used to enable default server side encryption"
  default = null
}
