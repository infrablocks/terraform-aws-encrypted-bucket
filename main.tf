data "template_file" "deny_unencrypted_object_uploads_fragment" {
  template = file("${path.module}/policy-fragments/deny-unencrypted-object-uploads.json.tpl")

  vars = {
    bucket_name = var.bucket_name
  }
}

data "template_file" "deny_unencrypted_inflight_operations_fragment" {
  template = file("${path.module}/policy-fragments/deny-unencrypted-inflight-operations.json.tpl")

  vars = {
    bucket_name = var.bucket_name
  }
}

data "template_file" "encrypted_bucket_policy" {
  template = coalesce(var.bucket_policy_template, file("${path.module}/policies/bucket-policy.json.tpl"))

  vars = {
    bucket_name = var.bucket_name
    deny_unencrypted_object_upload_fragment = data.template_file.deny_unencrypted_object_uploads_fragment.rendered
    deny_unencrypted_inflight_operations_fragment = data.template_file.deny_unencrypted_inflight_operations_fragment.rendered
  }
}

resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = var.bucket_name

  acl = var.acl

  versioning {
    enabled = true
    mfa_delete = var.mfa_delete
  }

  tags = merge(map("Name", var.bucket_name), var.tags)
}

resource "aws_s3_bucket_policy" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  policy = data.template_file.encrypted_bucket_policy.rendered
}
