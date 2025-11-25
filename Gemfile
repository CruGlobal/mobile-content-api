# frozen_string_literal: true

source "https://rubygems.org"
source "https://gems.contribsys.com/" do
  gem "sidekiq-pro"
end

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
# gem "sprockets-rails"

# Use sqlite3 as the database for Active Record
# gem "sqlite3", ">= 1.4"

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

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  # gem "capybara"
end

gem "pg"

gem "active_model_serializers", "0.10.15"
gem "active_storage_validations"
gem "adobe-campaign", "~> 0.4"
gem "apple_id"
gem "aws-sdk-s3"
gem "crowdin-api", "~> 1.13.0"
gem "datadog"
gem "dogstatsd-ruby", "~> 5.3"
gem "file_validators"
gem "googleauth"
gem "google-apis-analyticsreporting_v4"
gem "httparty"
gem "jwt"
gem "lograge"
gem "nokogiri"
gem "oj", "~> 3.16.0"
gem "ougai", "~> 2.0"
gem "rack-cors", require: "rack/cors"
gem "raddocs", github: "CruGlobal/raddocs"
gem "rest-client", "~> 2.1.0"
gem "rollbar"
gem "rubyzip", ">= 1.2.2"
gem "sidekiq", "~> 7.3"
gem "sidekiq-failures"
gem "sidekiq-unique-jobs"
gem "validates_email_format_of"

group :development, :test do
  gem "action-cable-testing"
  gem "brakeman"
  gem "bundler-audit"
  gem "dotenv-rails"
  gem "equivalent-xml", "~> 0.6.0"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "pry-byebug"
  gem "rspec"
  gem "rspec-rails", "~> 7.0"
  gem "rspec_api_documentation", github: "zipmark/rspec_api_documentation"
  gem "rubocop-rspec", require: false
  gem "simplecov-cobertura", require: false
  gem "spring-commands-rspec"
  gem "standard"
  gem "webmock", require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "amazing_print"
end
