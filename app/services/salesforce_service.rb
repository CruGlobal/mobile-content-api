# frozen_string_literal: true

class SalesforceService
  attr_accessor :follow_up

  def initialize(follow_up)
    @follow_up = follow_up
  end

  def subscribe!
    data = {
      email_address: follow_up.email,
      first_name: follow_up.name_params&.dig(:first_name),
      last_name: follow_up.name_params&.dig(:last_name),
      language_code: follow_up.language.code
    }.compact

    success = self.class.send_campaign_subscription(follow_up.email, follow_up.destination.service_name, data)
    raise Error::BadRequestError, "Failed to send campaign subscription to Salesforce for email: #{follow_up.email}" unless success
  end

  def self.get_access_token
    Rails.cache.fetch("salesforce_access_token", expires_in: 20.minutes) do
      auth_url = "#{ENV.fetch("SALESFORCE_AUTH_URI")}/v2/token"
      payload = {
        "grant_type" => "client_credentials",
        "client_id" => ENV.fetch("SALESFORCE_CLIENT_ID"),
        "client_secret" => ENV.fetch("SALESFORCE_CLIENT_SECRET")
      }

      response = RestClient.post(auth_url, payload.to_json, {content_type: :json, accept: :json})
      JSON.parse(response.body)["access_token"]
    end
  rescue RestClient::Exception => e
    Rails.logger.error("Failed to get Salesforce access token: #{e.message}")
    nil
  end

  def self.send_campaign_subscription(email, campaign_name, data = {})
    Rails.logger.info("SalesforceService#send_campaign_subscription enter, email: #{email}, campaign_name: #{campaign_name}, data: #{data.inspect}")

    return false unless (access_token = get_access_token)

    url = "#{ENV.fetch("SALESFORCE_REST_URI")}/hub/v1/dataevents/key:#{ENV.fetch("SALESFORCE_SFMC_DE_EXTERNAL_KEY")}/rowset"

    payload = [
      {
        keys: {
          subscriberkey: email,
          campaign: campaign_name
        },
        values: {
          subscriberkey: email,
          campaign: campaign_name,
          email_address: email
        }.merge(data)
      }
    ]

    headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }

    Rails.logger.info("SalesforceService#send_campaign_subscription payload: #{payload.to_json}\n\nheaders: #{headers.inspect}\n\nurl: #{url.inspect}\n\n")
    response = RestClient.post(url, payload.to_json, headers)
    Rails.logger.info("SalesforceService#send_campaign_subscription response: Code: #{response.code}\nHeaders: #{response.headers.inspect}\n\nBody: #{response.body}")

    response.code == 200
  rescue RestClient::Exception => e
    Rails.logger.error("SalesforceService#send_campaign_subscription Failed to send campaign data to Salesforce: #{e.message}\n#{e.backtrace}")
    raise
  end
end
