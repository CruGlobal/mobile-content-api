# frozen_string_literal: true

Datadog.configure do |c|
  # Tracer
  c.tracer hostname: ENV["DATADOG_HOST"],
           port: ENV["DATADOG_PORT"],
           tags: {app: ENV["PROJECT_NAME"]},
           debug: false,
           enabled: (ENV["DATADOG_TRACE"].to_s == "true"),
           env: Rails.env

  # Rails
  c.use :rails,
    service_name: ENV["PROJECT_NAME"],
    controller_service: "#{ENV["PROJECT_NAME"]}-controller",
    cache_service: "#{ENV["PROJECT_NAME"]}-cache",
    database_service: "#{ENV["PROJECT_NAME"]}-db"

  # Redis
  c.use :redis, service_name: "#{ENV["PROJECT_NAME"]}-redis"

  # Sidekiq
  c.use :sidekiq, service_name: "#{ENV["PROJECT_NAME"]}-sidekiq"

  # Net::HTTP
  c.use :http, service_name: "#{ENV["PROJECT_NAME"]}-http"

  c.user :active_model_serializers, service_name: "#{ENV["PROJECT_NAME"]}-ams"
end

# skipping the health check: if it returns true, the trace is dropped
Datadog::Pipeline.before_flush(Datadog::Pipeline::SpanFilter.new { |span|
  span.name == "rack.request" && span.get_tag("http.url") == "/monitors/lb"
})
