module "encrypted_bucket" {
  source = "../../../../"

  bucket_name = "${var.bucket_name}"
  acl = "${var.acl}"

  tags = {
    Thing = "value"
  }
}
