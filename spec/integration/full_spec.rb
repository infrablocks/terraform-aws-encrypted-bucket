# frozen_string_literal: true

require 'spec_helper'

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
end

describe 'full' do
  subject(:encrypted_bucket) { s3_bucket(bucket_name) }

  let(:region) do
    var(role: :full, name: 'region')
  end
  let(:bucket_name) do
    var(role: :full, name: 'encrypted_bucket_name')
  end
  let(:bucket_policy) do
    JSON.parse(find_bucket_policy(encrypted_bucket.id).policy.read)
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

  before(:context) do
    apply(role: :full)
  end

  after(:context) do
    destroy(
      role: :full,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  describe 'encrypted bucket' do
    it { is_expected.to exist }
    it { is_expected.to have_versioning_enabled }
    it { is_expected.to have_server_side_encryption(algorithm: 'aws:kms') }
    it { is_expected.not_to have_mfa_delete_enabled }
    it { is_expected.to have_tag('Name').value(bucket_name) }
    it { is_expected.to have_tag('AccessLogged').value('true') }

    # rubocop:disable RSpec/MultipleExpectations
    it 'has a private ACL' do
      expect(encrypted_bucket.acl_grants_count).to(eq(1))

      acl_grant = encrypted_bucket.acl.grants[0]
      expect(acl_grant.grantee.type).to(eq('CanonicalUser'))
      expect(acl_grant.permission).to(eq('FULL_CONTROL'))
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'has bucket key enabled' do
      expect(bucket_encryption.rules[0].bucket_key_enabled).to(be(true))
    end

    it 'denies encryption using the incorrect algorithm' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyEncryptionUsingIncorrectAlgorithm',
              deny_encryption_using_incorrect_algorithm_statement(
                bucket_name,
                'aws:kms'
              )
            ))
    end

    it 'denies unencrypted in flight operations' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyUnEncryptedInflightOperations',
              deny_un_encrypted_inflight_operations_statement(
                bucket_name
              )
            ))
    end

    it 'denies encryption using incorrect key' do
      expect(bucket_policy)
        .to(have_statement(
              'DenyEncryptionUsingIncorrectKey',
              deny_encryption_using_incorrect_key_statement(
                bucket_name,
                output(role: :full, name: 'kms_key_arn')
              )
            ))
    end

    it 'includes the contents of the source policy JSON' do
      expect(bucket_policy)
        .to(have_statement(
              'TestPolicy',
              {
                effect: 'Deny',
                principal: { 'AWS' => '*' },
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

    it 'sets block_public_acls to true in public access block settings' do
      expect(bucket_public_access_block.block_public_acls)
        .to(be(true))
    end

    it 'sets block_public_policy to true in public access block settings' do
      expect(bucket_public_access_block.block_public_policy)
        .to(be(true))
    end

    it 'sets ignore_public_acls to true in public access block settings' do
      expect(bucket_public_access_block.ignore_public_acls)
        .to(be(true))
    end

    it 'sets restrict_public_buckets to true in public ' \
       'access block settings' do
      expect(bucket_public_access_block.restrict_public_buckets)
        .to(be(true))
    end

    it 'has access logging enabled' do
      expect(encrypted_bucket).to(
        have_logging_enabled(
          target_bucket:
            output(role: :full, name: 'access_log_bucket_name'),
          target_prefix: 'logs/'
        )
      )
    end

    it 'outputs the bucket name' do
      expect(output(role: :full, name: 'bucket_name'))
        .to(eq(bucket_name))
    end

    it 'outputs the bucket ARN' do
      expect(output(role: :full, name: 'bucket_arn'))
        .to(eq("arn:aws:s3:::#{bucket_name}"))
    end
  end

  # rubocop:disable Metrics/MethodLength
  def deny_encryption_using_incorrect_algorithm_statement(
    bucket_name,
    algorithm
  )
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

  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def deny_encryption_using_incorrect_key_statement(
    bucket_name,
    kms_key_arn
  )
    {
      effect: 'Deny',
      principal: '*',
      action: 's3:PutObject',
      resource: "arn:aws:s3:::#{bucket_name}/*",
      condition: {
        'StringNotEqualsIfExists' => {
          's3:x-amz-server-side-encryption-aws-kms-key-id' => kms_key_arn
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

  # rubocop:enable Metrics/MethodLength
end
