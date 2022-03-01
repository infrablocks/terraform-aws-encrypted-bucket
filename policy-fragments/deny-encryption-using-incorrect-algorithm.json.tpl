{
  "Sid": "DenyEncryptionUsingIncorrectAlgorithm",
  "Effect": "Deny",
  "Principal": "*",
  "Action": ["s3:PutObject"],
  "Resource": ["arn:aws:s3:::${bucket_name}/*"],
  "Condition": {
    "Null": {
      "s3:x-amz-server-side-encryption": "false"
    },
    "StringNotEquals": {
      "s3:x-amz-server-side-encryption": "${sse_algorithm}"
    }
  }
}