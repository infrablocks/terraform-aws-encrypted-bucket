{
  "Sid": "DenyUnEncryptedInflightOperations",
  "Principal": "*",
  "Effect": "Deny",
  "Action": ["s3:*"],
  "Resource": ["arn:aws:s3:::${bucket_name}/*"],
  "Condition": {
    "Bool": {
        "aws:SecureTransport": "false"
    }
  }
}