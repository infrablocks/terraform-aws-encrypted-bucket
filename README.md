Terraform AWS Encrypted Bucket
==============================

<a href="https://go-atomic.io/"
style="display: block; padding: 5px;">
<img
src="https://github.com/infrablocks/terraform-aws-encrypted-bucket/raw/main/docs/images/atomic-logo-monochrome-2.png"
alt="Atomic Logo"
style="width: 220px">
</a>

Built with ❤️ by [Atomic](https://go-atomic.io/)

---

A Terraform module for building an encrypted bucket in AWS S3.

![Build Status](https://img.shields.io/circleci/build/github/infrablocks/terraform-aws-encrypted-bucket)
![License](https://img.shields.io/github/license/infrablocks/terraform-aws-encrypted-bucket)
![Release](https://img.shields.io/github/v/tag/infrablocks/terraform-aws-encrypted-bucket?label=release)

Usage
-----

To use the module, include something like the following in your Terraform
configuration:

```hcl-terraform
module "encrypted_bucket" {
  source = "git@github.com:infrablocks/terraform-aws-encrypted-bucket.git//src"

  bucket_name = "my-organisations-encrypted-bucket"
}
```

See the
[Terraform registry entry](https://registry.terraform.io/modules/infrablocks/encrypted-bucket/aws/latest)
for more details.

### Inputs

| Name                                                        | Description                                                                                                                           |  Default  | Required |
|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|:---------:|:--------:|
| bucket_name                                                 | The name to use for the encrypted S3 bucket.                                                                                          |     -     |   yes    |
| source_policy_document                                      | A source policy document for the bucket, additional statements to enable encryption will be added to the policy.                      |    ""     |    no    |
| acl                                                         | The [canned ACL](https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl) to apply.                              | "private" |    no    |
| tags                                                        | A map of additional tags to set on the bucket                                                                                         |    {}     |    no    |
| kms_key_arn                                                 | If provided, "aws:kms" encryption will be enforced using the KMS key with the provided ARN. By default, "AES-256" encryption is used. |    ""     |    no    |
| access_log_bucket_name                                      | The name of the bucket to use for access logging, required when enable_access_logging is "yes".                                       |    ""     |    no    |
| access_log_object_key_prefix                                | The key prefix to use for log objects for access logging.                                                                             |    ""     |    no    |
| public_access_block                                         | An object of public access block settings to apply to the bucket                                                                      | see below |    no    |
| public_access_block.block_public_acls                       | Whether to block public ACLs                                                                                                          |   false   |    no    |
| public_access_block.block_public_policy                     | Whether to block public bucket policies                                                                                               |   false   |    no    |
| public_access_block.ignore_public_acls                      | Whether to ignore public ACLs                                                                                                         |   false   |    no    |
| public_access_block.restrict_public_buckets                 | Whether to restrict public buckets                                                                                                    |   false   |    no    |
| enable_mfa_delete                                           | Whether or not to enable MFA delete on the bucket.                                                                                    |   false   |    no    |
| enable_versioning                                           | Whether or not to enable versioning on the bucket.                                                                                    |   true    |    no    |
| enable_access_logging                                       | Whether or not to enable access logging on the bucket.                                                                                |   false   |    no    |
| enable_bucket_key                                           | Whether or not to use an Amazon [S3 Bucket Key](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html) for SSE-KMS..  |   false   |    no    |
| enable_object_lock                                          | Whether or not to enable object lock on the bucket.                                                                                   |   false   |    no    |
| object_lock_configuration                                   | The configuration for the object lock.                                                                                                |   null    |    no    |
| cors_rules                                                  | The cors rules to be applied to the bucket                                                                                            |   null    |    no    |
| allow_destroy_when_objects_present                          | Whether or not to allow the bucket to be destroyed if it still contains objects.                                                      |   false   |    no    |
| include_deny_unencrypted_inflight_operations_statement      | Whether or not to include a bucket policy statement to deny unencrypted inflight operations.                                          |   true    |    no    |
| include_deny_encryption_using_incorrect_algorithm_statement | Whether or not to include a bucket policy statement to deny encryption using the incorrect algorithm.                                 |   true    |    no    |
| include_deny_encryption_using_incorrect_key_statement       | Whether or not to include a bucket policy statement to deny encryption using the incorrect key.                                       |   true    |    no    |

By default, a bucket policy that enforces encrypted inflight operations,
encryption using the correct algorithm, and encryption using the correct key is
applied to the bucket.

In the case that further statements need to be applied, a
`source_policy_document` can be provided and the additional statements will be
added to this policy before being attached to the bucket

The provided `tags` map, when present will be merged with a compulsory tags map
containing a `Name` tag equal to the bucket name.

### Outputs

| Name        | Description                    |
|-------------|--------------------------------|
| bucket_name | The name of the created bucket |
| bucket_arn  | The ARN of the created bucket  |

### Compatibility

This module is compatible with Terraform versions greater than or equal to
Terraform 1.0.

### Required Permissions

* s3:CreateBucket
* s3:ListBucket
* s3:GetBucketCORS
* s3:GetBucketVersioning
* s3:GetAccelerateConfiguration
* s3:GetBucketRequestPayment
* s3:GetBucketLogging
* s3:GetLifecycleConfiguration
* s3:GetReplicationConfiguration
* s3:GetBucketLocation
* s3:GetBucketTagging
* s3:PutBucketTagging
* s3:PutBucketVersioning
* s3:PutBucketPolicy
* s3:PutBucketAcl
* s3:DeleteBucketPolicy
* s3:DeleteBucket

If public access block settings are specified

* s3:GetBucketPolicyStatus
* s3:GetBucketPublicAccessBlock
* s3:PutBucketPublicAccessBlock

Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed 
on your development machine:

* Ruby (3.1.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv
* aws-vault

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 3.1.1
rbenv rehash
rbenv local 3.1.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# aws-vault
brew cask install

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

Running the build requires an AWS account and AWS credentials. You are free to 
configure credentials however you like as long as an access key ID and secret
access key are available. These instructions utilise 
[aws-vault](https://github.com/99designs/aws-vault) which makes credential
management easy and secure.

To provision module infrastructure, run tests and then destroy that 
infrastructure, execute:

```bash
aws-vault exec <profile> -- ./go
```

To provision the module prerequisites:

```bash
aws-vault exec <profile> -- ./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```bash
aws-vault exec <profile> -- ./go deployment:root:provision[<deployment_identifier>]
```

To destroy the module contents:

```bash
aws-vault exec <profile> -- ./go deployment:root:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```bash
aws-vault exec <profile> -- ./go deployment:prerequisites:destroy[<deployment_identifier>]
```

Configuration parameters can be overridden via environment variables:

```bash
DEPLOYMENT_IDENTIFIER=testing aws-vault exec <profile> -- ./go
```

When a deployment identifier is provided via an environment variable, 
infrastructure will not be destroyed at the end of test execution. This can
be useful during development to avoid lengthy provision and destroy cycles.

By default, providers will be downloaded for each terraform execution. To
cache providers between calls:

```bash
TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache" aws-vault exec <profile> -- ./go
```

### Common Tasks

#### Generating an SSH key pair

To generate an SSH key pair:

```
ssh-keygen -m PEM -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

#### Generating a self-signed certificate

To generate a self signed certificate:
```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

To decrypt the resulting key:

```
openssl rsa -in key.pem -out ssl.key
```

#### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```bash
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```bash
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at
https://github.com/infrablocks/terraform-aws-encrypted-bucket. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
-------

The library is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
