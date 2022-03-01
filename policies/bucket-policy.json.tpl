{
  "Version": "2012-10-17",
  "Statement": [
    %{if deny_encryption_using_incorrect_algorithm_fragment != ""}${deny_encryption_using_incorrect_algorithm_fragment}%{endif}
    %{if deny_encryption_using_incorrect_key_fragment != ""},${deny_encryption_using_incorrect_key_fragment}%{endif}
    %{if deny_unencrypted_inflight_operations_fragment != ""},${deny_unencrypted_inflight_operations_fragment}%{endif}
  ]
}