Terraform AWS Encrypted Bucket
==============================

[![CircleCI](https://circleci.com/gh/infrablocks/terraform-aws-encrypted-bucket.svg?style=svg)](https://circleci.com/gh/infrablocks/terraform-aws-encrypted-bucket)

A Terraform module for building an encrypted bucket in AWS S3.

Usage
-----

To use the module, include something like the following in your terraform configuration:

```hcl-terraform
module "encrypted_bucket" {
  source = "git@github.com:infrablocks/terraform-aws-encrypted-bucket.git//src"
  
  bucket_name = "my-organisations-encrypted-bucket"
}
```


### Inputs

| Name                   | Description                                      | Default      | Required |
|------------------------|--------------------------------------------------|:------------:|:--------:|
| bucket_name            | The name to use for the encrypted S3 bucket      | -            | yes      |
| bucket_policy_template | A template for the policy to apply to the bucket | see policies | no       |
| tags                   | A map of additional tags to set on the bucket    | {}           | no       |
| mfa_delete             | Enable MFA delete for either _Change the versioning state of your bucket_ or _Permanently delete an object version_ | false | no |  


By default, a bucket policy that enforces encrypted inflight operations and 
object uploads is applied to the bucket. In the case that further statements
need to be applied, a `bucket_policy_template` can be provided that will
receive `deny_unencrypted_object_upload_fragment` and 
`deny_unencrypted_inflight_operations_fragment` statement fragments along with
the `bucket_name` and the resulting policy will be used instead.

The provided `tags` map, when present will be merged with a compulsory tags map 
containing a `Name` tag equal to the bucket name.
  

### Outputs

| Name        | Description                    |
|-------------|--------------------------------|
| bucket_name | The name of the created bucket |


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

Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed on your
development machine:

* Ruby (2.6.0)
* Bundler
* git
* git-crypt
* gnupg
* direnv

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
rbenv install 2.6.0
rbenv rehash
rbenv local 2.6.0
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

To provision module infrastructure, run tests and then destroy that infrastructure,
execute:

```bash
./go
```

To provision the module contents:

```bash
./go deployment:harness:provision[<deployment_identifier>]
```

To destroy the module contents:

```bash
./go deployment:harness:destroy[<deployment_identifier>]
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at 
https://github.com/infrablocks/terraform-aws-encrypted-bucket. 
This project is intended to be a safe, welcoming space for collaboration, and 
contributors are expected to adhere to 
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


License
-------

The library is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
