# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk'
require 'pp'

RSpec::Matchers.define :have_statement do |*args|
  match do |actual|
    sid, expected = *args
    statements = actual['Statement']
    statement = statements.find { |s| s['Sid'] == sid }
    statement &&
      statement['Effect'] == expected[:effect] &&
      statement['Principal'] == expected[:principal] &&
      statement['Action'] == expected[:action] &&
      statement['Resource'] == expected[:resource] &&
      statement['Condition'] == expected[:condition]
  end

  match_when_negated do |actual|
    sid = *args
    statements = actual['Statement']
    statement = statements.find { |s| s['Sid'] == sid }
    statement.nil?
  end
end

describe 'Encrypted bucket' do
  let(:region) { vars.region }
  let(:bucket_name) { vars.bucket_name }
  let(:bucket) { s3_bucket(bucket_name) }
  let(:bucket_policy) do
    JSON.parse(find_bucket_policy(bucket.id).policy.read)
  end
  let(:bucket_public_access_block) do
    s3_client
      .get_public_access_block({ bucket: bucket_name })
      .public_access_block_configuration
  end
  let(:bucket_encryption) do
    s3_client
      .get_bucket_encryption({ bucket: bucket_name })
      .server_side_encryption_configuration
  end

  subject { bucket }

  context 'by default' do
    it { should exist }
    it { should have_versioning_enabled }
    it { should have_server_side_encryption(algorithm: 'AES256') }
    it { should_not have_mfa_delete_enabled }
    it { should_not have_logging_enabled }
    it { should have_tag('Name').value(bucket_name) }

    it 'has bucket key disabled' do
      expect(bucket_encryption.rules[0].bucket_key_enabled).to(be(false))
    end

    it 'has a private ACL' do
      expect(subject.acl_grants_count).to(eq(1))

      acl_grant = subject.acl.grants[0]
      expect(acl_grant.grantee.type).to(eq('CanonicalUser'))
      expect(acl_grant.permission).to(eq('FULL_CONTROL'))
    end

    it 'does not have block public access settings' do
      expect do
        s3_client.get_public_access_block({ bucket: bucket_name })
      end.to(raise_error(Aws::S3::Errors::NoSuchPublicAccessBlockConfiguration))
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyEncryptionUsingIncorrectAlgorithm',
              deny_encryption_using_incorrect_algorithm_statement(
                bucket_name,
                'AES256')))
    end

    it 'denies unencrypted in flight operations' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyUnEncryptedInflightOperations',
              deny_un_encrypted_inflight_operations_statement(
                bucket_name)))
    end

    it 'does not include a statement regarding usage of an incorrect key' do
      expect(bucket_policy)
        .not_to(have_statement('DenyEncryptionUsingIncorrectKey'))
    end

    it 'outputs the bucket name' do
      expect(output_for(:harness, 'bucket_name'))
        .to(eq(bucket_name))
    end

    it 'outputs the bucket ARN' do
      expect(output_for(:harness, 'bucket_arn'))
        .to(eq("arn:aws:s3:::#{bucket_name}"))
    end
  end

  context 'when acl provided' do
    before(:all) do
      provision(acl: 'public-read')
    end

    it 'uses specified acl' do
      expect(subject.acl_grants_count).to(eq(2))

      acl_grant = subject.acl.grants[0]
      expect(acl_grant.grantee.type).to(eq('CanonicalUser'))
      expect(acl_grant.permission).to(eq('FULL_CONTROL'))
      acl_grant = subject.acl.grants[1]
      expect(acl_grant.grantee.type).to(eq('Group'))
      expect(acl_grant.permission).to(eq('READ'))
    end
  end

  context 'when tags provided' do
    before(:all) do
      provision(tags: { "SomeTag" => "some-value" })
    end

    it { should have_tag('Name').value(bucket_name) }
    it { should have_tag('SomeTag').value("some-value") }
  end

  context 'when source_policy_json provided' do
    before(:all) do
      provision(source_policy_json:
                  File.read('spec/test-source-policy.json.tpl')
                      .gsub('${bucket_name}', vars.bucket_name))
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyEncryptionUsingIncorrectAlgorithm',
              deny_encryption_using_incorrect_algorithm_statement(
                bucket_name,
                'AES256')))
    end

    it 'denies unencrypted in flight operations' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyUnEncryptedInflightOperations',
              deny_un_encrypted_inflight_operations_statement(
                bucket_name)))
    end

    it 'does not include a statement regarding usage of an incorrect key' do
      expect(bucket_policy)
        .not_to(have_statement('DenyEncryptionUsingIncorrectKey'))
    end

    it 'includes the contents of the source policy JSON' do
      expect(bucket_policy)
        .to(have_statement(
              'TestPolicy',
              {
                effect: 'Deny',
                principal: '*',
                action: 's3:*',
                resource: "arn:aws:s3:::#{bucket_name}/*",
                condition: {
                  'IpAddress' => {
                    'aws:SourceIp' => '8.8.8.8/32'
                  }
                }
              }
            ))
    end
  end

  context 'when bucket_policy_template provided' do
    before(:all) do
      provision(bucket_policy_template:
                  File.read('spec/test-bucket-policy.json.tpl'))
    end

    it 'includes statement fragments specified in template' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyUnEncryptedInflightOperations',
              deny_un_encrypted_inflight_operations_statement(
                bucket_name)))
    end

    it 'does not include statement fragments not specified in template' do
      expect(bucket_policy)
        .not_to(have_statement('DenyEncryptionUsingIncorrectAlgorithm'))
      expect(bucket_policy)
        .not_to(have_statement('DenyEncryptionUsingIncorrectKey'))
    end

    it 'includes the  contents of the bucket policy template' do
      expect(bucket_policy)
        .to(have_statement(
              'TestPolicy',
              {
                effect: 'Deny',
                principal: '*',
                action: 's3:*',
                resource: "arn:aws:s3:::#{bucket_name}/*",
                condition: {
                  'IpAddress' => {
                    'aws:SourceIp' => '8.8.8.8/32'
                  }
                }
              }
            ))
    end
  end

  context 'when kms_key_arn provided' do
    before(:all) do
      provision(
        kms_key_arn: output_for(:prerequisites, 'kms_key_arn'))
    end

    it { should have_server_side_encryption(algorithm: 'aws:kms') }

    it 'denies encryption using the incorrect algorithm' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyEncryptionUsingIncorrectAlgorithm',
              deny_encryption_using_incorrect_algorithm_statement(
                bucket_name,
                'aws:kms')))
    end

    it 'denies encryption using the incorrect key' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyEncryptionUsingIncorrectKey',
              deny_encryption_using_incorrect_key_statement(
                bucket_name,
                output_for(:prerequisites, 'kms_key_arn'))))
    end

    it 'denies unencrypted in flight operations' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyUnEncryptedInflightOperations',
              deny_un_encrypted_inflight_operations_statement(
                bucket_name)))
    end
  end

  context 'when enable_bucket_key is "yes"' do
    before(:all) do
      provision(
        kms_key_arn: output_for(:prerequisites, 'kms_key_arn'),
        enable_bucket_key: 'yes')
    end

    it 'has bucket key enabled' do
      expect(bucket_encryption.rules[0].bucket_key_enabled).to(be(true))
    end
  end

  context 'when enable_bucket_key is "no"' do
    before(:all) do
      provision(
        kms_key_arn: output_for(:prerequisites, 'kms_key_arn'),
        enable_bucket_key: 'no')
    end

    it 'has bucket key disabled' do
      expect(bucket_encryption.rules[0].bucket_key_enabled).to(be(false))
    end
  end

  context 'when enable_versioning is "no"' do
    before(:all) do
      provision(enable_versioning: 'no')
    end

    it { should_not have_versioning_enabled }
  end

  context 'when enable_versioning is "yes"' do
    before(:all) do
      provision(enable_versioning: 'yes')
    end

    it { should have_versioning_enabled }
  end

  context 'when public_access_block provided' do
    context 'with block_public_acls true' do
      before(:all) do
        provision(
          public_access_block: {
            block_public_acls: true,
            block_public_policy: false,
            ignore_public_acls: false,
            restrict_public_buckets: false
          })
      end

      it 'sets block_public_acls to true in public access block settings' do
        expect(bucket_public_access_block.block_public_acls)
          .to(eq(true))
      end
    end

    context 'with block_public_policy true' do
      before(:all) do
        provision(
          public_access_block: {
            block_public_acls: false,
            block_public_policy: true,
            ignore_public_acls: false,
            restrict_public_buckets: false
          })
      end

      it 'sets block_public_policy to true in public access block settings' do
        expect(bucket_public_access_block.block_public_policy)
          .to(eq(true))
      end
    end

    context 'with ignore_public_acls true' do
      before(:all) do
        provision(
          public_access_block: {
            block_public_acls: false,
            block_public_policy: false,
            ignore_public_acls: true,
            restrict_public_buckets: false
          })
      end

      it 'sets ignore_public_acls to true in public access block settings' do
        expect(bucket_public_access_block.ignore_public_acls)
          .to(eq(true))
      end
    end

    context 'with restrict_public_buckets true' do
      before(:all) do
        provision(
          public_access_block: {
            block_public_acls: false,
            block_public_policy: false,
            ignore_public_acls: false,
            restrict_public_buckets: true
          })
      end

      it 'sets restrict_public_buckets to true in public access block settings' do
        expect(bucket_public_access_block.restrict_public_buckets)
          .to(eq(true))
      end
    end
  end

  context 'when mfa_delete is "true"' do
    let(:plan_output) do
      capture_stdout do
        plan(mfa_delete: 'true',
             enable_mfa_delete: '')
      end
    end

    subject { plan_output }

    it { is_expected.to include('mfa_delete = false -> true') }
  end

  context 'when enable_mfa_delete is "yes"' do
    let(:plan_output) do
      capture_stdout do
        plan(enable_mfa_delete: 'yes',
             mfa_delete: '')
      end
    end

    subject { plan_output }

    it { is_expected.to include('mfa_delete = false -> true') }
  end

  context 'when enable_access_logging is "yes"' do
    before(:all) do
      provision(
        enable_access_logging: 'yes',
        access_log_bucket_name:
          output_for(:prerequisites, 'access_log_bucket_name'),
        access_log_object_key_prefix: 'logs/')
    end

    it do
      should(
        have_logging_enabled(
          target_bucket:
            output_for(:prerequisites, 'access_log_bucket_name'),
          target_prefix: 'logs/'))
    end
  end

  context 'when enable_access_logging is "no"' do
    before(:all) do
      provision(enable_access_logging: 'no')
    end

    it { should_not(have_logging_enabled) }
  end

  context 'when allow_destroy_when_objects_present is "yes"' do
    before(:all) do
      provision(allow_destroy_when_objects_present: 'yes')
    end

    it 'destroys the bucket even if it contains an object' do
      s3_client
        .put_object({
                      body: 'hello',
                      bucket: bucket_name,
                      key: 'some-object',
                      server_side_encryption: 'AES256'
                    })

      begin
        destroy
      rescue RubyTerraform::Errors::ExecutionError => e
        # no-op
      end

      bucket_list = s3_client.list_buckets
      bucket_names = bucket_list.buckets.map { |b| b[:name] }

      expect(bucket_names).not_to(include(bucket_name))
    end
  end

  context 'when allow_destroy_when_objects_present is "no"' do
    before(:all) do
      provision(allow_destroy_when_objects_present: 'no')
    end

    it 'does not destroy the bucket if it contains an object' do
      s3_client
        .put_object({
                      body: 'hello',
                      bucket: bucket_name,
                      key: 'some-object',
                      server_side_encryption: 'AES256'
                    })

      begin
        destroy
      rescue RubyTerraform::Errors::ExecutionError => e
        # no-op
      end

      bucket_list = s3_client.list_buckets
      bucket_names = bucket_list.buckets.map { |b| b[:name] }

      expect(bucket_names).to(include(bucket_name))

      bucket = Aws::S3::Bucket.new(bucket_name)
      bucket.delete!
    end
  end

  def deny_encryption_using_incorrect_algorithm_statement(
    bucket_name,
    algorithm)
    {
      effect: 'Deny',
      principal: '*',
      action: 's3:PutObject',
      resource: "arn:aws:s3:::#{bucket_name}/*",
      condition: {
        'Null' => {
          's3:x-amz-server-side-encryption' => 'false'
        },
        'StringNotEquals' => {
          's3:x-amz-server-side-encryption' => algorithm
        }
      }
    }
  end

  def deny_encryption_using_incorrect_key_statement(
    bucket_name,
    kms_key_arn)
    {
      effect: 'Deny',
      principal: '*',
      action: 's3:PutObject',
      resource: "arn:aws:s3:::#{bucket_name}/*",
      condition: {
        "StringNotEqualsIfExists" => {
          "s3:x-amz-server-side-encryption-aws-kms-key-id" => kms_key_arn
        }
      }
    }
  end

  def deny_un_encrypted_inflight_operations_statement(
    bucket_name)
    {
      effect: 'Deny',
      principal: '*',
      action: 's3:*',
      resource: "arn:aws:s3:::#{bucket_name}/*",
      condition: {
        'Bool' => {
          'aws:SecureTransport' => 'false'
        }
      }
    }
  end

  def capture_stdout(&block)
    output = StringIO.new

    RubyTerraform.configure do |c|
      c.stdout = output
    end

    block.call

    RubyTerraform.configure do |c|
      c.stdout = $stdout
    end

    output.string
  end
end
