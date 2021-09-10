variable "region" {}
variable "bucket_name" {}
variable "mfa_delete" {}

variable "acl" {}

variable "include_source_policy_json" {}

variable "allow_destroy_when_objects_present" {}

variable "kms_key_arn" {
  default = ""
}
