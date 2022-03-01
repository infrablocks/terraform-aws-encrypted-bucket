{
  "Version": "2012-10-17",
  "Statement": [
    ${deny_unencrypted_inflight_operations_fragment},
    {
      "Sid": "TestPolicy",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${bucket_name}/*",
      "Condition": {
        "IpAddress": {"aws:SourceIp": "8.8.8.8/32"}
      }
    }
  ]
}
