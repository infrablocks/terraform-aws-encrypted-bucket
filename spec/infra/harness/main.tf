module "encrypted_bucket" {
  source = "../../../../"

  bucket_name = "${var.bucket_name}"

  mfa_delete = "${var.mfa_delete}"

  tags = {
    Thing = "value"
  }
}
