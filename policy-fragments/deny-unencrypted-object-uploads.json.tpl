{
  "Sid": "DenyUnEncryptedObjectUploads",
  "Effect": "Deny",
  "Action": ["s3:PutObject"],
  "Resource": ["arn:aws:s3:::${bucket_name}/*"],

  "Condition": {
    "StringNotEquals": {
        "s3:x-amz-server-side-encryption": "${sse_algorithm}"
    }
  },

  "Principal": "*"
}