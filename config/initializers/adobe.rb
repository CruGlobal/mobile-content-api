# frozen_string_literal: true

begin
  # Get credentials from database
  destination = Destination.adobe_campaigns.first
  if destination&.access_key_id.present? && destination&.access_key_secret.present?
    Adobe::Campaign.configure do |config|
      config.org_id = ENV["ADOBE_CAMPAIGN_ORG_ID"]
      config.org_name = ENV["ADOBE_CAMPAIGN_ORG_NAME"]
      config.tech_acct = ENV["ADOBE_CAMPAIGN_TECH_ACCT"]
      config.signed_jwt = ENV["ADOBE_CAMPAIGN_SIGNED_JWT"]
      config.api_key = destination.access_key_id
      config.api_secret = destination.access_key_secret
    end
    # Currently the adobe-campaigns gems does not support multiple adobe account, we
    # will issue a warning if there are different credentials on database
    if Destination.adobe_campaigns.distinct(:access_key_id).count > 1
      Rollbar.warning("There are different adobe credentials on the destinations table.")
    end
  else
    Rollbar.warning("Adobe Campaigns was not initialized, check info on destinations table")
  end
rescue ::ActiveRecord::NoDatabaseError, ::ActiveRecord::StatementInvalid
  warn("[WARN] database doesn't exist. Skipping AdobeCampaigns initialization")
end
