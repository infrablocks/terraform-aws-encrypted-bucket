{
  "Sid": "DenyEncryptionUsingIncorrectKey",
  "Effect": "Deny",
  "Principal": "*",
  "Action": ["s3:PutObject"],
  "Resource": ["arn:aws:s3:::${bucket_name}/*"],
  "Condition": {
    "StringNotEqualsIfExists": {
      "s3:x-amz-server-side-encryption-aws-kms-key-id": "${kms_key_arn}"
    }
  }
}