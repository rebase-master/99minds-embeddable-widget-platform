require "acts_as_tenant/sidekiq"

ActsAsTenant.configure do |config|
  config.require_tenant = true
end

Sidekiq.configure_server do |config|
  config.client_middleware { |chain| chain.add ActsAsTenant::Sidekiq::Client }
  config.server_middleware { |chain| chain.add ActsAsTenant::Sidekiq::Server }
end

Sidekiq.configure_client do |config|
  config.client_middleware { |chain| chain.add ActsAsTenant::Sidekiq::Client }
end
