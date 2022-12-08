# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk'

describe 'encrypted bucket' do
  let(:bucket_name) do
    var(role: :root, name: 'bucket_name')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .once)
    end

    it 'uses the provided bucket name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(:bucket, bucket_name))
    end

    it 'does not allow the bucket to be destroyed when objects are present' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(:force_destroy, false))
    end

    it 'includes the bucket name as a tag on the bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Name: bucket_name
                )
              ))
    end

    it 'uses a bucket ACL of private' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_acl')
              .with_attribute_value(:acl, 'private'))
    end

    it 'does not enable access logging' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_s3_bucket_logging'))
    end

    it 'enables bucket versioning' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_versioning')
              .with_attribute_value(
                [:versioning_configuration, 0, :status],
                'Enabled'
              ))
    end

    it 'does not enable MFA delete' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_versioning')
              .with_attribute_value(
                [:versioning_configuration, 0, :mfa_delete],
                'Disabled'
              ))
    end

    it 'enables server side encryption using the Amazon default key' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :apply_server_side_encryption_by_default, 0,
                 :sse_algorithm],
                'AES256'
              ))
    end

    it 'does not set a KMS key' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :apply_server_side_encryption_by_default, 0,
                 :kms_master_key_id],
                ''
              ))
    end

    it 'does not enable bucket keys' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :bucket_key_enabled],
                false
              ))
    end

    it 'does not have block public access settings' do
      expect(@plan)
        .not_to(include_resource_creation(
                  type: 'aws_s3_bucket_public_access_block'
                ))
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_encryption_using_incorrect_algorithm_statement(
                    bucket_name,
                    'AES256'
                  )
                )
              ))
    end

    it 'denies unencrypted in flight operations' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_un_encrypted_inflight_operations_statement(
                    bucket_name
                  )
                )
              ))
    end

    it 'does not include a statement regarding usage of an incorrect key' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
                  .with_attribute_value(
                    :policy,
                    a_policy_with_statement(
                      Sid: 'DenyEncryptionUsingIncorrectKey'
                    )
                  ))
    end

    it 'outputs the bucket ARN' do
      expect(@plan)
        .to(include_output_creation(name: 'bucket_arn'))
    end

    it 'outputs the bucket name' do
      expect(@plan)
        .to(include_output_creation(name: 'bucket_name'))
    end
  end

  describe 'when bucket ACL provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.acl = 'public-read'
      end
    end

    it 'uses the provided bucket ACL' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_acl')
              .with_attribute_value(:acl, 'public-read'))
    end
  end

  context 'when source_policy_document provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.source_policy_document =
          File.read('spec/unit/test-source-policy.json.tpl')
              .gsub('${bucket_name}', vars.bucket_name)
      end
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_encryption_using_incorrect_algorithm_statement(
                    bucket_name,
                    'AES256'
                  )
                )
              ))
    end

    it 'denies unencrypted in flight operations' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_un_encrypted_inflight_operations_statement(
                    bucket_name
                  )
                )
              ))
    end

    it 'does not include a statement regarding usage of an incorrect key' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
                  .with_attribute_value(
                    :policy,
                    a_policy_with_statement(
                      Sid: 'DenyEncryptionUsingIncorrectKey'
                    )
                  ))
    end

    it 'includes the contents of the source policy JSON' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  Sid: 'TestPolicy',
                  Effect: 'Deny',
                  Principal: '*',
                  Action: 's3:*',
                  Resource: "arn:aws:s3:::#{bucket_name}/*",
                  Condition: {
                    IpAddress: {
                      'aws:SourceIp': ['8.8.8.8/32']
                    }
                  }
                )
              ))
    end
  end

  context 'when tags provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.tags = { SomeTag: 'some-value' }
      end
    end

    it 'includes the bucket name as a tag on the bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Name: bucket_name
                )
              ))
    end

    it 'includes the provided tags on the bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  SomeTag: 'some-value'
                )
              ))
    end
  end

  context 'when include_deny_unencrypted_inflight_operations_statement ' \
          'is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_deny_unencrypted_inflight_operations_statement = 'false'
      end
    end

    it 'does not deny unencrypted in flight operations' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
                  .with_attribute_value(
                    :policy,
                    a_policy_with_statement(
                      deny_un_encrypted_inflight_operations_statement(
                        bucket_name
                      )
                    )
                  ))
    end
  end

  context 'when include_deny_unencrypted_inflight_operations_statement ' \
          'is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_deny_unencrypted_inflight_operations_statement = 'true'
      end
    end

    it 'denies unencrypted in flight operations' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_un_encrypted_inflight_operations_statement(
                    bucket_name
                  )
                )
              ))
    end
  end

  context 'when include_deny_encryption_using_incorrect_algorithm_statement ' \
          'is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_deny_encryption_using_incorrect_algorithm_statement =
          'false'
      end
    end

    it 'does not deny encryption using the incorrect algorithm' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
                  .with_attribute_value(
                    :policy,
                    a_policy_with_statement(
                      deny_encryption_using_incorrect_algorithm_statement(
                        bucket_name,
                        'AES256'
                      )
                    )
                  ))
    end
  end

  context 'when include_deny_encryption_using_incorrect_algorithm_statement ' \
          'is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_deny_encryption_using_incorrect_algorithm_statement =
          'true'
      end
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_encryption_using_incorrect_algorithm_statement(
                    bucket_name,
                    'AES256'
                  )
                )
              ))
    end
  end

  context 'when include_deny_encryption_using_incorrect_key_statement ' \
          'is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_deny_encryption_using_incorrect_key_statement = 'false'
        vars.kms_key_arn = output(role: :prerequisites, name: 'kms_key_arn')
      end
    end

    it 'does not deny encryption using incorrect key' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
                  .with_attribute_value(
                    :policy,
                    a_policy_with_statement(
                      deny_encryption_using_incorrect_key_statement(
                        bucket_name,
                        output(role: :prerequisites, name: 'kms_key_arn')
                      )
                    )
                  ))
    end
  end

  context 'when include_deny_encryption_using_incorrect_key_statement ' \
          'is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_deny_encryption_using_incorrect_key_statement = 'true'
        vars.kms_key_arn = output(role: :prerequisites, name: 'kms_key_arn')
      end
    end

    it 'denies encryption using incorrect key' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_encryption_using_incorrect_key_statement(
                    bucket_name,
                    output(role: :prerequisites, name: 'kms_key_arn')
                  )
                )
              ))
    end
  end

  context 'when kms_key_arn provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.kms_key_arn = output(role: :prerequisites, name: 'kms_key_arn')
      end
    end

    it 'enables server side encryption using KMS as the algorithm' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :apply_server_side_encryption_by_default, 0,
                 :sse_algorithm],
                'aws:kms'
              ))
    end

    it 'uses the provided KMS key for server side encryption' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :apply_server_side_encryption_by_default, 0,
                 :kms_master_key_id],
                output(role: :prerequisites, name: 'kms_key_arn')
              ))
    end

    it 'denies unencrypted in flight operations' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_un_encrypted_inflight_operations_statement(
                    bucket_name
                  )
                )
              ))
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  deny_encryption_using_incorrect_algorithm_statement(
                    bucket_name,
                    'aws:kms'
                  )
                )
              ))
    end

    it 'denies encryption using incorrect key' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_policy'
        )
                  .with_attribute_value(
                    :policy,
                    a_policy_with_statement(
                      deny_encryption_using_incorrect_key_statement(
                        bucket_name,
                        output(role: :prerequisites, name: 'kms_key_arn')
                      )
                    )
                  ))
    end
  end

  context 'when enable_bucket_key is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.kms_key_arn = output(role: :prerequisites, name: 'kms_key_arn')
        vars.enable_bucket_key = true
      end
    end

    it 'enables bucket keys' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :bucket_key_enabled],
                true
              ))
    end
  end

  context 'when enable_bucket_key is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.kms_key_arn = output(role: :prerequisites, name: 'kms_key_arn')
        vars.enable_bucket_key = false
      end
    end

    it 'does not enable bucket keys' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket_server_side_encryption_configuration'
        )
              .with_attribute_value(
                [:rule, 0,
                 :bucket_key_enabled],
                false
              ))
    end
  end

  context 'when enable_versioning is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_mfa_delete = true
        vars.enable_versioning = false
      end
    end

    it 'does not enable bucket versioning' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_versioning')
              .with_attribute_value(
                [:versioning_configuration, 0, :status],
                'Disabled'
              ))
    end
  end

  context 'when enable_versioning is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_versioning = true
      end
    end

    it 'enables bucket versioning' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_versioning')
              .with_attribute_value(
                [:versioning_configuration, 0, :status],
                'Enabled'
              ))
    end
  end

  context 'when enable_mfa_delete is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_mfa_delete = true
      end
    end

    it 'enables MFA delete' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_versioning')
              .with_attribute_value(
                [:versioning_configuration, 0, :mfa_delete],
                'Enabled'
              ))
    end
  end

  context 'when enable_mfa_delete is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_mfa_delete = false
      end
    end

    it 'does not enable MFA delete' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_versioning')
              .with_attribute_value(
                [:versioning_configuration, 0, :mfa_delete],
                'Disabled'
              ))
    end
  end

  context 'when public_access_block provided' do
    context 'with block_public_acls true' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.public_access_block = {
            block_public_acls: true,
            block_public_policy: false,
            ignore_public_acls: false,
            restrict_public_buckets: false
          }
        end
      end

      it 'sets block_public_acls to true in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_acls, true))
      end

      it 'sets block_public_policy to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_policy, false))
      end

      it 'sets ignore_public_acls to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:ignore_public_acls, false))
      end

      it 'sets restrict_public_buckets to false in public access block ' \
         'settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:restrict_public_buckets, false))
      end
    end

    context 'with block_public_policy true' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.public_access_block = {
            block_public_acls: false,
            block_public_policy: true,
            ignore_public_acls: false,
            restrict_public_buckets: false
          }
        end
      end

      it 'sets block_public_acls to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_acls, false))
      end

      it 'sets block_public_policy to true in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_policy, true))
      end

      it 'sets ignore_public_acls to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:ignore_public_acls, false))
      end

      it 'sets restrict_public_buckets to false in public access block ' \
         'settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:restrict_public_buckets, false))
      end
    end

    context 'with ignore_public_acls true' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.public_access_block = {
            block_public_acls: false,
            block_public_policy: false,
            ignore_public_acls: true,
            restrict_public_buckets: false
          }
        end
      end

      it 'sets block_public_acls to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_acls, false))
      end

      it 'sets block_public_policy to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_policy, false))
      end

      it 'sets ignore_public_acls to true in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:ignore_public_acls, true))
      end

      it 'sets restrict_public_buckets to false in public access block ' \
         'settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:restrict_public_buckets, false))
      end
    end

    context 'with restrict_public_buckets true' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.public_access_block = {
            block_public_acls: false,
            block_public_policy: false,
            ignore_public_acls: false,
            restrict_public_buckets: true
          }
        end
      end

      it 'sets block_public_acls to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_acls, false))
      end

      it 'sets block_public_policy to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:block_public_policy, false))
      end

      it 'sets ignore_public_acls to false in public access block settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:ignore_public_acls, false))
      end

      it 'sets restrict_public_buckets to true in public access block ' \
         'settings' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_public_access_block'
          )
                .with_attribute_value(:restrict_public_buckets, true))
      end
    end
  end

  context 'when allow_destroy_when_objects_present is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.allow_destroy_when_objects_present = true
      end
    end

    it 'enables force destroy on the bucket' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket'
        )
              .with_attribute_value(:force_destroy, true))
    end
  end

  context 'when allow_destroy_when_objects_present is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.allow_destroy_when_objects_present = false
      end
    end

    it 'does not enable force destroy on the bucket' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_s3_bucket'
        )
              .with_attribute_value(:force_destroy, false))
    end
  end

  context 'when enable_access_logging is true' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_access_logging = true
        vars.access_log_bucket_name =
          output(role: :prerequisites, name: 'access_log_bucket_name')
        vars.access_log_object_key_prefix = 'logs/'
      end
    end

    it 'enables access logging' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_logging')
              .once)
    end

    it 'uses the provided access log bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_logging')
              .with_attribute_value(
                :target_bucket,
                output(role: :prerequisites, name: 'access_log_bucket_name')
              ))
    end

    it 'uses the provided access log object key prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_logging')
              .with_attribute_value(
                :target_prefix,
                'logs/'
              ))
    end
  end

  context 'when enable_access_logging is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_access_logging = false
      end
    end

    it 'does not enable access logging' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_s3_bucket_logging'))
    end
  end

  context 'when object_lock_enabled is false' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.enable_object_lock = false
      end
    end

    it 'does not enable bucket object lock' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :object_lock_enabled,
                false
              ))
    end

    it 'does not create bucket object lock configuration' do
      expect(@plan)
        .not_to(include_resource_creation(
                  type: 'aws_s3_bucket_object_lock_configuration'
                ))
    end
  end

  context 'when object_lock_enabled is true' do
    context 'with object_lock_configuration not set' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.enable_object_lock = true
          vars.object_lock_configuration = nil
        end
      end

      it 'enables bucket object lock' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_s3_bucket')
                .with_attribute_value(
                  :object_lock_enabled,
                  true
                ))
      end

      it 'does not create bucket object lock configuration' do
        expect(@plan)
          .not_to(include_resource_creation(
                    type: 'aws_s3_bucket_object_lock_configuration'
                  ))
      end
    end

    context 'with object_lock_configuration set to retain for days' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.enable_object_lock = true
          vars.object_lock_configuration = {
            mode: 'COMPLIANCE',
            days: 10,
            years: nil
          }
        end
      end

      it 'enables bucket object lock' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_s3_bucket')
                .with_attribute_value(
                  :object_lock_enabled,
                  true
                ))
      end

      it 'creates bucket object lock configuration' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_object_lock_configuration'
          )
                .once)
      end

      it 'sets the specified mode in default retention rule' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_object_lock_configuration'
          )
                .with_attribute_value(
                  [:rule, 0,
                   :default_retention, 0,
                   :mode],
                  'COMPLIANCE'
                ))
      end

      it 'sets days to 10 in default retention rule' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_object_lock_configuration'
          )
                .with_attribute_value(
                  [:rule, 0,
                   :default_retention, 0,
                   :days],
                  10
                ))
      end
    end

    context 'with object_lock_configuration set to retain for years' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.enable_object_lock = true
          vars.object_lock_configuration = {
            mode: 'GOVERNANCE',
            years: 1,
            days: nil
          }
        end
      end

      it 'enables bucket object lock' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_s3_bucket')
                .with_attribute_value(
                  :object_lock_enabled,
                  true
                ))
      end

      it 'creates bucket object lock configuration' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_object_lock_configuration'
              )
                .once)
      end

      it 'sets the specified mode in default retention rule' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_object_lock_configuration'
              )
                .with_attribute_value(
                  [:rule, 0,
                   :default_retention, 0,
                   :mode],
                  'GOVERNANCE'
                ))
      end

      it 'sets years to 1 in default retention rule' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_s3_bucket_object_lock_configuration'
              )
                .with_attribute_value(
                  [:rule, 0,
                   :default_retention, 0,
                   :years],
                  1
                ))
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def deny_encryption_using_incorrect_algorithm_statement(
    bucket_name,
    algorithm
  )
    {
      Sid: 'DenyEncryptionUsingIncorrectAlgorithm',
      Effect: 'Deny',
      Principal: '*',
      Action: 's3:PutObject',
      Resource: "arn:aws:s3:::#{bucket_name}/*",
      Condition: {
        Null: {
          's3:x-amz-server-side-encryption': ['false']
        },
        StringNotEquals: {
          's3:x-amz-server-side-encryption': [algorithm]
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def deny_un_encrypted_inflight_operations_statement(
    bucket_name
  )
    {
      Sid: 'DenyUnEncryptedInflightOperations',
      Effect: 'Deny',
      Principal: '*',
      Action: 's3:*',
      Resource: "arn:aws:s3:::#{bucket_name}/*",
      Condition: {
        Bool: {
          'aws:SecureTransport': ['false']
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def deny_encryption_using_incorrect_key_statement(
    bucket_name,
    kms_key_arn
  )
    {
      Sid: 'DenyEncryptionUsingIncorrectKey',
      Effect: 'Deny',
      Principal: '*',
      Action: 's3:PutObject',
      Resource: "arn:aws:s3:::#{bucket_name}/*",
      Condition: {
        StringNotEqualsIfExists: {
          's3:x-amz-server-side-encryption-aws-kms-key-id': [kms_key_arn]
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength
end
