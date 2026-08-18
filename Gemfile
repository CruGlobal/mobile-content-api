# frozen_string_literal: true

source "https://rubygems.org"
source "https://gems.contribsys.com/" do
  gem "sidekiq-pro"
end

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.5"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
# gem "propshaft" # Declined: no asset pipeline in this API app — serves JSON + raddocs static docs
# Use sqlite3 as the database for Active Record
# gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
# gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
# gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
# Declined: this app deliberately uses :redis_cache_store, Sidekiq Pro, and the redis Action Cable adapter
# gem "solid_cache"
# gem "solid_queue"
# gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
# gem "kamal", require: false # Declined: deployed to AWS ECS via Docker

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  # gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  # gem "capybara"
end

gem "active_model_serializers", "0.10.16"
gem "active_storage_validations"
gem "adobe-campaign", "~> 0.4"
gem "apple_id"
gem "aws-sdk-s3"
gem "connection_pool", "< 3.0" # Conflict with redis_cache_store in Rails < 8.1.2
gem "crowdin-api", "~> 1.14.0"
gem "datadog"
gem "dogstatsd-ruby", "~> 5.3"
gem "file_validators"
gem "google-apis-analyticsreporting_v4"
gem "googleauth"
gem "httparty"
gem "jwt"
gem "lograge"
gem "nokogiri"
gem "oj", "~> 3.17.0"
gem "ougai", "~> 2.1"
gem "pg"
gem "rack-cors", require: "rack/cors"
gem "raddocs", github: "CruGlobal/raddocs"
gem "redis", ">= 4.0.1" # Dropped from the 8.0 skeleton; still used for :redis_cache_store and the Action Cable redis adapter
gem "rest-client", "~> 2.1.0"
gem "rollbar"
gem "rubyzip", ">= 1.2.2"
gem "sidekiq", "~> 8.0"
gem "sidekiq-failures"
gem "sidekiq-unique-jobs"
gem "validates_email_format_of"

group :development, :test do
  gem "action-cable-testing"
  gem "bundler-audit"
  gem "dotenv-rails"
  gem "equivalent-xml", "~> 0.6.0"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "pry-byebug"
  gem "rspec"
  gem "rspec-rails", "~> 8.0"
  gem "rspec_api_documentation", github: "zipmark/rspec_api_documentation"
  gem "rubocop-rspec", require: false
  gem "simplecov-cobertura", require: false
  gem "standard"
  gem "webmock", require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "amazing_print"
end
