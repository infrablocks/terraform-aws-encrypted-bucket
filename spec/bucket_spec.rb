require 'spec_helper'
require 'pp'

describe 'Encrypted bucket' do
  let(:region) { vars.region }
  let(:bucket_name) { vars.bucket_name }

  subject { s3_bucket(bucket_name) }

  context 'with default variables' do
    it { should exist }
    it { should have_versioning_enabled }
    it { should_not have_mfa_delete_enabled }
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
      expect(output_for(:harness, 'bucket_name')).to(eq(bucket_name))
    end
  end

  context 'with public-read acl' do
    before(:all) do
      reprovision(acl: 'public-read')
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
