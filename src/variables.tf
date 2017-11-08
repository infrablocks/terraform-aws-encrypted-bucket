variable "region" {}

variable "bucket_name" {}
variable "bucket_policy_template" {
  default = ""
}

variable "tags" {
  type = "map"
  default = {}
}
