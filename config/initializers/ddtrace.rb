# frozen_string_literal: true

base_name = ENV["PROJECT_NAME"]
enabled = ENV["DATADOG_TRACE"].to_s == "true"

Rails.configuration.datadog_trace = {
  enabled: enabled,
  auto_instrument: true,
  auto_instrument_redis: true,
  auto_instrument_grape: false,
  default_service: base_name,
  default_controller_service: "#{base_name}-controller",
  default_cache_service: "rails-cache",
  default_database_service: "#{base_name}-db",
  template_base_path: "views/",
  tracer: Datadog.tracer,
  debug: false,
  trace_agent_hostname: ENV["DATADOG_HOST"],
  trace_agent_port: 8126,
  env: Rails.env,
  tags: {app: base_name},
}
