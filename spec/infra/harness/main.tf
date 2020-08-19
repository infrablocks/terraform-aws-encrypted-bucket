data "template_file" "test_policy" {
  template = file("${path.module}/resources/test-policy.json.tpl")

  vars = {
    bucket_name = var.bucket_name
  }
}

module "encrypted_bucket" {
  source = "../../../../"

  bucket_name = var.bucket_name
  acl = var.acl

  mfa_delete = var.mfa_delete

  source_policy_json = var.include_source_policy_json ? data.template_file.test_policy.rendered : ""

  tags = {
    Thing = "value"
  }
}
