require 'securerandom'
require 'ostruct'
require 'confidante'

require_relative 'paths'
require_relative 'public_address'

class Configuration
  def initialize
    @random_deployment_identifier = SecureRandom.hex[0, 8].to_s
    @default_public_gpg_key_path =
        "#{project_directory}/config/secrets/gpg/user.gpg.public"
    @default_private_gpg_key_path =
        "#{project_directory}/config/secrets/gpg/user.gpg.private"
    @default_gpg_key_passphrase =
        File.read("#{project_directory}/config/secrets/gpg/user.passphrase")
    @delegate = Confidante.configuration
  end

  def deployment_identifier
    deployment_identifier_for({})
  end

  def deployment_identifier_for(overrides)
    OpenStruct.new(overrides).deployment_identifier ||
        ENV['DEPLOYMENT_IDENTIFIER'] ||
        @random_deployment_identifier
  end

  def public_gpg_key_path
    public_gpg_key_path_for({})
  end

  def public_gpg_key_path_for(overrides)
    OpenStruct.new(overrides).public_gpg_key_path ||
        ENV['PUBLIC_GPG_KEY_PATH'] ||
        @default_public_gpg_key_path
  end

  def private_gpg_key_path
    private_gpg_key_path_for({})
  end

  def private_gpg_key_path_for(overrides)
    OpenStruct.new(overrides).private_gpg_key_path ||
        ENV['PRIVATE_GPG_KEY_PATH'] ||
        @default_private_gpg_key_path
  end

  def gpg_key_passphrase
    gpg_key_passphrase_for({})
  end

  def gpg_key_passphrase_for(overrides)
    OpenStruct.new(overrides).gpg_key_passphrase ||
        ENV['GPG_KEY_PASSPHRASE'] ||
        @default_gpg_key_passphrase
  end

  def project_directory
    Paths.project_root_directory
  end

  def work_directory
    @delegate.work_directory
  end

  def public_address
    PublicAddress.as_ip_address
  end

  def for(role, overrides = nil)
    @delegate
        .for_scope(
            role: role,
            project_directory: project_directory
        )
        .for_overrides(
            overrides.to_h.merge({
                public_address: public_address,
                project_directory: project_directory,
                deployment_identifier: deployment_identifier_for(overrides),
                public_gpg_key_path: public_gpg_key_path_for(overrides),
                private_gpg_key_path: private_gpg_key_path_for(overrides),
                gpg_key_passphrase: gpg_key_passphrase_for(overrides)
            }))
  end
end