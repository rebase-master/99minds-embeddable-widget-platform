# Rails 8 Active Record Encryption — bridges env vars to the config attributes
# so we can boot via docker-compose (or any env-var-driven environment) without
# committing a master.key or coordinating credentials.yml.enc.
#
# Fail-fast: missing any of the three vars raises KeyError at boot.

Rails.application.config.active_record.encryption.tap do |c|
  c.primary_key        = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
  c.deterministic_key  = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
  c.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
end
