# frozen_string_literal: true
source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.2'
# Use PostgreSQL as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 3.0', require: false

gem 'active_model_serializers', '= 0.10.5'
gem 'nokogiri', '>= 1.8.5'
gem 'oj', '~> 3.7.9'
gem 'paperclip'
gem 'rest-client', '~> 2.0.1'
gem 'rubyzip', '>= 1.2.2'
gem 'syslog-logger'
gem 'validates_email_format_of'

# External (services)
gem 'aws-sdk'
gem 'aws-sdk-rails'
gem 'ddtrace'
gem 'rollbar'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'codecov', require: false
  gem 'dotenv-rails'
  gem 'equivalent-xml', '~> 0.6.0'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'rspec'
  gem 'rspec-rails', '~> 3.6'
  gem 'rspec_api_documentation'
  gem 'rubocop', '~> 0.66.0', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'webmock', require: false
end

gem 'raddocs'

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'awesome_print'
  gem 'listen', '~> 3.0.5'
  gem 'rack-cors', require: 'rack/cors'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'dogstatsd-ruby'
gem 'lograge'
gem 'ougai', '~> 1.7'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
