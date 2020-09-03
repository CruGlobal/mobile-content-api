# frozen_string_literal: true

require_relative "./fixtures/adobe_campaign_parsed_json_fixtures"

module AdobeCampaignStubHelpers
  include ::AdobeCampaignParsedJsonFixtures

  def stub_find_an_existing_subscription_example(campaign_name)
    expect(Adobe::Campaign::Service).not_to receive(:post_subscription)

    stub_get_profile_by_email
    stub_get_request_subscription(campaign_name)
  end

  def stub_create_a_new_subscription_example(profile_hash, campaign_name)
    stub_get_profile_by_email(without_results: true)
    stub_get_request_subscription(campaign_name, without_results: true)
    stub_post_new_profile(profile_hash)
    stub_get_campaign_service(campaign_name)
    stub_post_new_subscription(campaign_name)
  end

  def stub_get_profile_by_email(without_results: false)
    expect(Adobe::Campaign::Profile).to receive(:by_email).and_return(
      "content" => without_results ? [] : [adobe_campaign_profile],
      "count" => {
        "href" => "https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile//byEmail/_count?email=test@user.com&" \
          "_lineStart=@p0BJhFcngt0uJqiMKQFpKjnmAXUWtiMSQnfZJwFOr7MDWWz8",
        "value" => without_results ? 0 : 1
      },
      "serverSidePagination" => false
    )
  end

  def stub_get_request_subscription(campaign_name, without_results: false)
    expect(Adobe::Campaign::Base).to receive(:get_request).with("https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/" \
                                                                "@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoTomQPm9e3ETJ_s2pUrH5" \
                                                                "DVPZuk_Z0W41Q6y_gWBZNXq0tVd1bKDLzkB92oTy7ZdPgYWNvX/subscriptions/")
      .and_return(
        "content" => without_results ? [] : [adobe_campaign_subscription(campaign_name)],
        "count" => {
          "href" => "https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@Ga7hAokNoLpeirz_nSoRL0CKJGFPEHwPfkxSH-6JI3i__49" \
                    "-4qoY-OcQnrq31JC49daKHmf9lVybo__N9gTiPaREcVIuBu794uz7cU21yq3vq7Vz/subscriptions//_count?_lineStart=@a-xJyJp1E7H" \
                    "jLc3TBySO1jY_J3GHc6EdySQtvLYKkhvVmRu4",
          "value" => without_results ? 0 : 1
        },
        "serverSidePagination" => false
      )
  end

  def stub_get_campaign_service(campaign_name)
    expect(Adobe::Campaign::Service).to receive(:find).with(campaign_name).and_return(
      "content" => [adobe_campaign(campaign_name)],
      "count" => {
        "href" => "https://mc.adobe.io/cru/campaign/profileAndServices/service//byText/_count?text=#{campaign_name}" \
                  "&_lineStart=@p0BJhFcngt0uJqiMKQFpKjnmAXUWtiMSQnfZJwFOr7MDWWz8",
        "value" => 1
      },
      "serverSidePagination" => true
    )
  end

  def stub_post_new_subscription(campaign_name)
    service_subs_url = "https://mc.adobe.io/cru/campaign/profileAndServices/service/@KyJ3Rl7A2R7sb62mI4fNrovCP0hqyIsIqwertN4Bhg" \
                       "6QZBWQCOiscEBMIytndUdVOdMgkFjbFDuSXRKQSewjug_1LPqU-riINCYmOCldu0kUGcTg/subscriptions/"
    pkey = "@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoQR8nTDjEp7xY55lHFPiEffYnCm8nsIW0zIvoVt0-3zrQ_GjTs"
    expect(Adobe::Campaign::Service).to receive(:post_subscription).with(service_subs_url, pkey)
      .and_return(adobe_campaign_subscription(campaign_name))
  end

  def stub_post_new_profile(profile_hash)
    expect(Adobe::Campaign::Profile).to receive(:post).with(profile_hash).and_return(adobe_campaign_profile)
  end
end
