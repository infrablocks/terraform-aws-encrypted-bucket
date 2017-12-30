module "encrypted_bucket" {
  source = "../../../../"

  bucket_name = "${var.bucket_name}"

  tags = {
    Thing = "value"
  }
}
