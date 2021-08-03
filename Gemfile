# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.4"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0.3"
# Use sqlite3 as the database for Active Record
# gem 'sqlite3', '~> 1.4'
# Use Puma as the app server
gem "puma", "~> 4.3"
# Use SCSS for stylesheets
# gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem "image_processing", "~> 1.12"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.6"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "pg"

gem "active_model_serializers", "0.10.12"
gem "active_storage_validations"
gem "adobe-campaign", "~> 0.4.0"
gem "aws-sdk-s3"
gem "ddtrace"
gem "dogstatsd-ruby"
gem "file_validators"
gem "google-api-client", "~> 0.53", require: "google/apis/analyticsreporting_v4"
gem "httparty"
gem "jwt"
gem "lograge"
gem "oj", "~> 3.12.3"
gem "ougai", "~> 2.0"
gem "raddocs"
gem "redis"
gem "rest-client", "~> 2.1.0"
gem "rollbar"
gem "rubyzip", ">= 1.2.2"
gem "validates_email_format_of"

group :development, :test do
  gem "action-cable-testing"
  gem "brakeman"
  gem "bundler-audit"
  gem "codecov", require: false
  gem "dotenv-rails"
  gem "equivalent-xml", "~> 0.6.0"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "pry-byebug"
  gem "rspec"
  gem "rspec-rails", "~> 5.0"
  gem "rspec_api_documentation"
  gem "rubocop-rspec", require: false
  gem "simplecov", require: false
  gem "standard"
  gem "webmock", require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "amazing_print"
  gem "rack-cors", require: "rack/cors"
end
