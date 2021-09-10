require 'spec_helper'
require 'aws-sdk'
require 'pp'

describe 'Encrypted bucket' do
  let(:region) { vars.region }
  let(:bucket_name) { vars.bucket_name }

  subject { s3_bucket(bucket_name) }

  context 'with default variables' do
    it { should exist }
    it { should have_versioning_enabled }
    it { should_not have_mfa_delete_enabled }
    it { should_not have_default_encryption_enabled }
    it { should have_tag('Name').value(bucket_name) }
    it { should have_tag('Thing').value("value") }

    it 'is private' do
      expect(subject.acl_grants_count).to(eq(1))

      acl_grant = subject.acl.grants[0]
      expect(acl_grant.grantee.type).to(eq('CanonicalUser'))
      expect(acl_grant.permission).to(eq('FULL_CONTROL'))
    end

    it 'denies unencrypted object uploads' do
      policy = JSON.parse(
          find_bucket_policy(subject.id).policy.read)
      statements = policy['Statement']
      statement = statements.find do |s|
        s['Sid'] == 'DenyUnEncryptedObjectUploads'
      end

      expect(statement['Effect']).to(eq('Deny'))
      expect(statement['Principal']).to(eq('*'))
      expect(statement['Action']).to(eq('s3:PutObject'))
      expect(statement['Resource']).to(eq("arn:aws:s3:::#{bucket_name}/*"))
      expect(statement['Condition'])
          .to(eq(JSON.parse(
              '{"StringNotEquals": {"s3:x-amz-server-side-encryption": "AES256"}}')))
    end

    it 'denies unencrypted in flight operations' do
      policy = JSON.parse(
          find_bucket_policy(subject.id).policy.read)
      statements = policy['Statement']
      statement = statements.find do |s|
        s['Sid'] == 'DenyUnEncryptedInflightOperations'
      end

      expect(statement['Effect']).to(eq('Deny'))
      expect(statement['Principal']).to(eq('*'))
      expect(statement['Action']).to(eq('s3:*'))
      expect(statement['Resource']).to(eq("arn:aws:s3:::#{bucket_name}/*"))
      expect(statement['Condition'])
          .to(eq(JSON.parse(
              '{"Bool": {"aws:SecureTransport": "false"}}')))
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

  context 'with source policy json' do
    before(:all) do
      provision(include_source_policy_json: "true")
    end

    it 'denies unencrypted object uploads' do
      policy = JSON.parse(
          find_bucket_policy(subject.id).policy.read)
      statements = policy['Statement']
      statement = statements.find do |s|
        s['Sid'] == 'DenyUnEncryptedObjectUploads'
      end

      expect(statement['Effect']).to(eq('Deny'))
      expect(statement['Principal']).to(eq('*'))
      expect(statement['Action']).to(eq('s3:PutObject'))
      expect(statement['Resource']).to(eq("arn:aws:s3:::#{bucket_name}/*"))
      expect(statement['Condition'])
          .to(eq(JSON.parse(
              '{"StringNotEquals": {"s3:x-amz-server-side-encryption": "AES256"}}')))
    end

    it 'denies unencrypted in flight operations' do
      policy = JSON.parse(
          find_bucket_policy(subject.id).policy.read)
      statements = policy['Statement']
      statement = statements.find do |s|
        s['Sid'] == 'DenyUnEncryptedInflightOperations'
      end

      expect(statement['Effect']).to(eq('Deny'))
      expect(statement['Principal']).to(eq('*'))
      expect(statement['Action']).to(eq('s3:*'))
      expect(statement['Resource']).to(eq("arn:aws:s3:::#{bucket_name}/*"))
      expect(statement['Condition'])
          .to(eq(JSON.parse(
              '{"Bool": {"aws:SecureTransport": "false"}}')))
    end

    it 'has TestPolicy' do
      policy = JSON.parse(
          find_bucket_policy(subject.id).policy.read)
      statements = policy['Statement']
      statement = statements.find do |s|
        s['Sid'] == 'TestPolicy'
      end

      expect(statement['Effect']).to(eq('Deny'))
      expect(statement['Principal']).to(eq('*'))
      expect(statement['Action']).to(eq('s3:*'))
      expect(statement['Resource']).to(eq("arn:aws:s3:::#{bucket_name}/*"))
      expect(statement['Condition'])
          .to(eq(JSON.parse(
              '{"IpAddress": {"aws:SourceIp": "8.8.8.8/32"}}')))
    end
  end

  context 'with public-read acl' do
    before(:all) do
      provision(acl: 'public-read')
    end

    it 'is public-read' do
      expect(subject.acl_grants_count).to(eq(2))

      acl_grant = subject.acl.grants[0]
      expect(acl_grant.grantee.type).to(eq('CanonicalUser'))
      expect(acl_grant.permission).to(eq('FULL_CONTROL'))
      acl_grant = subject.acl.grants[1]
      expect(acl_grant.grantee.type).to(eq('Group'))
      expect(acl_grant.permission).to(eq('READ'))
    end
  end

  context 'when mfa_delete specified' do
    let(:plan_output) {
      capture_stdout do
        plan(mfa_delete: 'true')
      end
    }

    subject { plan_output }

    it {
      puts subject
      is_expected.to include('mfa_delete = false -> true')
    }
  end

  context 'when allow_destroy_when_objects_present is "yes"' do
    before(:all) do
      provision(allow_destroy_when_objects_present: 'yes')
    end

    it 'destroys the bucket even if it contains an object' do
      s3_client.put_object({
          body: "hello",
          bucket: bucket_name,
          key: "some-object",
          server_side_encryption: "AES256",
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
      s3_client.put_object({
          body: "hello",
          bucket: bucket_name,
          key: "some-object",
          server_side_encryption: "AES256",
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
