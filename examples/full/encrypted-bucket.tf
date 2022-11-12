module "encrypted_bucket" {
  source = "../../"

  bucket_name = var.encrypted_bucket_name

  source_policy_document = data.aws_iam_policy_document.additional_statement.json

  tags = {
    AccessLogged : true
  }

  kms_key_arn = aws_kms_key.encryption_key.arn

  enable_access_logging        = true
  access_log_bucket_name       = var.access_log_bucket_name
  access_log_object_key_prefix = "logs/"

  public_access_block = {
    block_public_acls: true
    block_public_policy: true
    ignore_public_acls: true
    restrict_public_buckets: true
  }

  enable_bucket_key                  = true
  allow_destroy_when_objects_present = true
}
