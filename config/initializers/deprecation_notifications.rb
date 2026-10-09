# Log each distinct deprecation once per process (production and staging use :notify).
seen = Concurrent::Map.new
ActiveSupport::Notifications.subscribe(/\Adeprecation\./) do |event|
  payload = event.payload
  next unless seen.put_if_absent(payload[:message], true).nil?
  Rails.logger.warn("#{payload[:message]} [#{payload[:gem_name]} #{payload[:deprecation_horizon]}]")
end
