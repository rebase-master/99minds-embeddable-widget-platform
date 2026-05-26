source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2", ">= 8.1.2.1"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Redis client — shared by Action Cable, Rails cache, and Sidekiq.
gem "redis", ">= 5"

# Background jobs.
gem "sidekiq", "~> 7.3"

# Multi-tenancy. See TRADEOFFS.md Stage 1.2 for choice rationale.
gem "acts_as_tenant", "~> 1.0"

# CORS for SDK-facing endpoints (storefronts live on arbitrary domains).
gem "rack-cors"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# NOTE: API key hashing uses SHA256 + ENV['API_KEY_PEPPER'] — bcrypt is NOT included by design (TRADEOFFS.md Stage 1.2b).
# NOTE: SDK session tokens use ActiveSupport::MessageVerifier — jwt gem is NOT included by design (TRADEOFFS.md Stage 1.5d).

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Test framework.
  gem "rspec-rails", "~> 7.1"

  # Factories for test/dev seed data.
  gem "factory_bot_rails", "~> 6.4"
end

group :test do
  # Matchers for ActiveRecord/Rails associations, validations, etc.
  gem "shoulda-matchers", "~> 6.4"
end
