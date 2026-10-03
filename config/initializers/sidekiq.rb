require "datadog/statsd"
require "redis"

redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, permitted_classes: [Symbol], aliases: true)["sidekiq"]

redis_settings = {url: Redis.new(redis_conf).id}

SidekiqUniqueJobs.configure do |config|
  # don't use SidekiqUniqueJobs in test env because it will cause head-scratching
  # https://github.com/mhenrixon/sidekiq-unique-jobs#uniqueness
  # https://github.com/mperham/sidekiq/wiki/Ent-Unique-Jobs#enable (not our gem but Sidekiq Enterprise suggested the same thing)
  config.enabled = !Rails.env.test?
end

Sidekiq.configure_client do |config|
  config.redis = redis_settings

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

# Sidekiq Pro features; the open-source gem falls back to plain push/fetch and
# the basic scheduler, which are fine for local development.
Sidekiq::Client.reliable_push! if Sidekiq::Client.respond_to?(:reliable_push!)

Sidekiq.configure_server do |config|
  if config.respond_to?(:super_fetch!)
    config.super_fetch!
    config.reliable_scheduler!
  end
  config.redis = redis_settings

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.failures_default_mode = :exhausted

if ENV["AWS_EXECUTION_ENV"].present? && defined?(Sidekiq::Pro)
  Sidekiq::Pro.dogstatsd = -> { Datadog::Statsd.new socket_path: "/var/run/datadog/dsd.socket" }
end

Sidekiq.default_job_options = {"backtrace" => true}
