# frozen_string_literal: true

class AdobeCampaign
  attr_accessor :follow_up

  def initialize(follow_up)
    @follow_up = follow_up
  end

  def subscribe!
    find_adobe_subscription || subscribe_to_adobe_campaign
  end

  class << self
    def adobe_campaign_service(service_name)
      Adobe::Campaign::Service.find(service_name).dig("content", 0)
    end
  end

  private

  def service_name
    follow_up.destination.service_name
  end

  def find_adobe_subscription
    profile = find_or_create_adobe_profile
    prof_subs_url = profile["subscriptions"]["href"]
    subscriptions = Adobe::Campaign::Base.get_request(prof_subs_url)["content"]
    subscriptions.find { |sub| sub["serviceName"] == service_name }
  end

  def find_or_create_adobe_profile
    @adobe_profile ||= find_on_adobe_campaign
    @adobe_profile ||= post_to_adobe_campaign
  end

  def find_on_adobe_campaign
    Adobe::Campaign::Profile.by_email(follow_up.email)["content"][0]
  end

  def post_to_adobe_campaign
    Adobe::Campaign::Profile.post("email": follow_up.email,
                                  "firstName": follow_up.name_params[:first_name],
                                  "lastName": follow_up.name_params[:last_name],
                                  "preferredLanguage": follow_up.language.code)
  end

  def subscribe_to_adobe_campaign
    profile = find_or_create_adobe_profile
    service = self.class.adobe_campaign_service(follow_up.destination.service_name)
    service_subs_url = service["subscriptions"]["href"]
    Adobe::Campaign::Service.post_subscription(service_subs_url, profile["PKey"])
  end
end
