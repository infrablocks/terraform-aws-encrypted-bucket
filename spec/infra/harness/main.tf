data "template_file" "test_policy" {
  template = file("${path.module}/resources/test-policy.json.tpl")

  vars = {
    bucket_name = var.bucket_name
  }
}

module "encrypted_bucket" {
  # This makes absolutely no sense. I think there's a bug in terraform.
  source = "./../../../../../../../"

  bucket_name = var.bucket_name
  acl = var.acl

  mfa_delete = var.mfa_delete

  source_policy_json = var.include_source_policy_json ? data.template_file.test_policy.rendered : ""

  allow_destroy_when_objects_present = var.allow_destroy_when_objects_present

  kms_key_arn = var.kms_key_arn

  tags = {
    Thing = "value"
  }
}
