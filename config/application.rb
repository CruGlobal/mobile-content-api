# frozen_string_literal: true
require_relative 'boot'

require 'rails/all'
require 'fileutils'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/log/logger'
module MobileContentApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Enable ougai
    config.logger = Log::Logger.new(Rails.root.join('log', 'datadog.log'))

    ActiveModelSerializers.config.adapter = :json_api
    FileUtils.mkdir_p('pages')
  end
end
