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
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Send all logs to stdout, which docker reads and sends to datadog.
    config.logger = Log::Logger.new($stdout) unless Rails.env.test? # we don't need a logger in test env

    config.redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, permitted_classes: [Symbol], aliases: true)
    redis_cache_conf = config.redis_conf["cache"]
    redis_cache_conf[:url] = "redis://" + redis_cache_conf[:host] + "/" + redis_cache_conf[:db].to_s
    config.cache_store = :redis_cache_store, redis_cache_conf

    ActiveModelSerializers.config.adapter = :json_api
    FileUtils.mkdir_p("pages")
  end
end
