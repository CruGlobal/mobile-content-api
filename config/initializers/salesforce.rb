# frozen_string_literal: true

# :nocov:
Rails.application.config.to_prepare do
  # Salesforce configuration is handled via environment variables:
  # SALESFORCE_AUTH_URI
  # SALESFORCE_CLIENT_ID
  # SALESFORCE_CLIENT_SECRET
  # SALESFORCE_REST_URI
  # SALESFORCE_SFMC_DE_EXTERNAL_KEY
  
  Rails.logger.info("Salesforce service configured successfully")
rescue ::ActiveRecord::NoDatabaseError, ::ActiveRecord::StatementInvalid
  warn("[WARN] database doesn't exist. Skipping Salesforce initialization")
end
# :nocov:
