variable "bucket_name" {
  description = "The name to use for the encrypted S3 bucket."
}
variable "bucket_policy_template" {
  description = "A template for the policy to apply to the bucket."
  default = ""
}
variable "acl" {
  description = "The canned ACL to apply. Defaults to private."
  default = "private"
}

variable "tags" {
  description = "A map of additional tags to set on the bucket."
  type = "map"
  default = {}
}
