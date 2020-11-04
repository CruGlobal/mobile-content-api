# frozen_string_literal: true

Rails.application.configure do
  config.logger = Log::Logger.new($stdout)
  config.lograge.enabled = true
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      {msg: "Request"}.merge(data)
    end
  end
  config.lograge.base_controller_class = ["ActionController::API", "ActionController::Base"]
  config.lograge.ignore_actions = ["MonitorsController#lb"]
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    {
      params: (event.payload[:params] || event.payload[:data]).except(*exceptions)
    }
  end
  config.lograge.custom_payload do |controller|
    user_id = begin
      controller.respond_to?(:current_user) ? controller.current_user.try(:id) : nil
    rescue Auth::ApplicationController::AuthenticationError
      nil
    end
    {
      user_id: user_id,
      request: controller.request
    }
  end
end
