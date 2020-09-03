# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "fileutils"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/log/logger"
module MobileContentApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Enable ougai
    if Rails.env.development? || Rails.const_defined?("Console")
      config.logger = Log::Logger.new($stdout)
    elsif !Rails.env.test? # use default logger in test env
      config.logger = Log::Logger.new(Rails.root.join("log", "datadog.log"))
    end

    config.redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, [Symbol], [], true)
    redis_cache_conf = config.redis_conf["cache"]
    redis_cache_conf[:url] = "redis://" + redis_cache_conf[:host] + "/" + redis_cache_conf[:db].to_s
    config.cache_store = :redis_cache_store, redis_cache_conf

    ActiveModelSerializers.config.adapter = :json_api
    FileUtils.mkdir_p("pages")
  end
end
