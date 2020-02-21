# frozen_string_literal: true

Adobe::Campaign.configure do |config|
  config.org_id = ENV["ADOBE_ORG_ID"]
  config.org_name = ENV["ADOBE_ORG_NAME"]
  config.tech_acct = ENV["ADOBE_TECH_ACCT"]
  config.api_key = ENV["ADOBE_API_KEY"]
  config.api_secret = ENV["ADOBE_API_SECRET"]
  config.signed_jwt = ENV["ADOBE_SIGNED_JWT"]
end
