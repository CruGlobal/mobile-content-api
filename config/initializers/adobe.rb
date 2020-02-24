# frozen_string_literal: true

# Get credentials from database
destination = Destination.adobe_campaigns.first
if destination&.adobe_api_key.present? && destination&.adobe_api_secret.present?
  Adobe::Campaign.configure do |config|
    config.org_id = ENV["ADOBE_ORG_ID"]
    config.org_name = ENV["ADOBE_ORG_NAME"]
    config.tech_acct = ENV["ADOBE_TECH_ACCT"]
    config.signed_jwt = ENV["ADOBE_SIGNED_JWT"]
    config.api_key = destination.adobe_api_key
    config.api_secret = destination.adobe_api_secret
  end
  # Currently the adobe-campaigns gems does not support multiple adobe account, we
  # will issue a warning if there are different credentials on database
  if Destination.adobe_campaigns.distinct(:adobe_api_key).count > 1
    Rollbar.warning("There are different adobe credentials on the destinations table.")
  end
else
  Rollbar.warning("Adobe Campaigns was not initialized, check info on destinations table")
end
