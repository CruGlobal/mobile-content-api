# frozen_string_literal: true
require_relative 'boot'

require 'rails/all'
require 'fileutils'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MobileContentApi
  class Application < Rails::Application
    ActiveModelSerializers.config.adapter = :json_api
    FileUtils.mkdir_p('pages')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
