# frozen_string_literal: true

# Rollbar can't use Rails' compiled filter list, so this copy is what masks these names in
# Rollbar reports. It must load after filter_parameter_logging.rb (initializers load by file
# name), which is why it can't live in 01_rollbar.rb.
Rollbar.configure do |config|
  config.scrub_fields |= Rails.application.config.filter_parameters.select { |filter| filter.is_a?(Symbol) || filter.is_a?(String) }
  config.scrub_fields |= %w[_mobile_content_api_session]
  config.scrub_headers |= %w[Referer]
end
