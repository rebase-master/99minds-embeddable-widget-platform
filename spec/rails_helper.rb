# Set required ENV vars before Rails boots (docker-compose.yml values, already committed).
ENV["RAILS_ENV"] = "test" # force; docker-compose sets development, ||= wouldn't override
ENV["API_KEY_PEPPER"] ||= "7fc7c2150e375759b81cc6f00741f419a0f3ea0a066625e7f4d6a8e72899c398"
ENV["SDK_JWT_SIGNING_KEY"] ||= "10ac657201bb2f6362714dfaac0cd5b21ce846eaa0db391f1698c3e72b75fd1a"
ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"] ||= "2c53664fd09ffd1ca3a08f769526bbec97ffa72f516d0a845f7821d2dde33550"
ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"] ||= "b31e39603e1a601c337584a464c42f06a4e395de8dc581b14883ba6993c8f4de"
ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"] ||= "5d755e5f5c651e69cd46cf353c2b318807ea967cf49fd7fd08c5a5b3ae436d7f"

require "spec_helper"
require_relative "../config/environment"
require "rspec/rails"
require 'shoulda/matchers'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.include AuthHelpers, type: :request
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework(:rspec)
    with.library(:rails)
  end
end
