# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.6"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 7.0.7"
# Use sqlite3 as the database for Active Record
# gem 'sqlite3', '~> 1.4'
# Use Puma as the app server
gem "puma", "~> 5.0"
# Use SCSS for stylesheets
# gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker', '~> 5.0'
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
gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 3.0"
  gem "listen", "~> 3.3"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver", ">= 4.0.0.rc1"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "pg"

gem "active_model_serializers", "0.10.13"
gem "active_storage_validations"
gem "adobe-campaign", "~> 0.4.1"
gem "aws-sdk-s3"
gem "ddtrace", "~> 1.10"
gem "dogstatsd-ruby", "~> 5.3"
gem "file_validators"
gem "google-apis-analyticsreporting_v4"
gem "httparty"
gem "jwt"
gem "lograge"
gem "nokogiri"
gem "oj", "~> 3.16.0"
gem "ougai", "~> 2.0"
gem "rack-cors", require: "rack/cors"
gem "raddocs"
# action cable currently requires redis < 5. This should be fixed in rails >= 7.0.4
# relevant issue: https://github.com/redis/redis-rb/issues/1142
gem "redis", "< 5"
gem "rest-client", "~> 2.1.0"
gem "rollbar"
gem "rubyzip", ">= 1.2.2"
gem "validates_email_format_of"
gem "googleauth"
gem "apple_id"

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
  gem "rspec-rails", "~> 6.0"
  gem "rspec_api_documentation"
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

# Temporary security fix until new Ruby release
gem "uri", "~> 0.10.3"
