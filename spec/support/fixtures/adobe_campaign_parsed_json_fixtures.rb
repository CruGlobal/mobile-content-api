# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/LineLength
module AdobeCampaignParsedJsonFixtures
  def adobe_campaign_profile
    {
      'PKey' => '@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoQR8nTDjEp7xY55lHFPiEffYnCm8nsIW0zIvoVt0-3zrQ_GjTs',
      'age' => 0,
      'birthDate' => '',
      'blackList' => false,
      'blackListEmail' => false,
      'blackListFax' => false,
      'blackListMobile' => false,
      'blackListPhone' => false,
      'blackListPostalMail' => false,
      'blackListPushnotification' => false,
      'created' => '2018-04-05 23:20:14.989Z',
      'cryptedId' => '2sEnzQAmEYxZNM1DU1HEsODdTPpn1REzNGJpWqfQObpHg4aBDm9IPtV8qGBSC1L/0EjWWg==',
      'cusAccountName' => '',
      'cusAccountNumber' => '',
      'cusAccountTitle' => '',
      'cusAccountType' => '',
      'cusAddressName' => '',
      'cusBdayofMonth' => 0,
      'cusBirthMonth' => 0,
      'cusBirthYear' => 0,
      'cusBusinessPhone' => '',
      'cusCampusName' => '',
      'cusCompany' => '',
      'cusContactId' => '',
      'cusDEPTNAME' => '',
      'cusDonor' => 'N',
      'cusDonorClass' => '',
      'cusEmployee' => 'N',
      'cusEventAttendeelink' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoQR8nTDjEp7xY55lHFPiEffYnCm8nsIW0zIvoVt0-3zrQ_GjTs/cusEventAttendeelink/'
      },
      'cusFinanceAccountNumber' => '',
      'cusGCXUrlslinktoProfile' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoTry94ItJPgAbfCOQNN4SKxKc2ArQdTul7snRO40-8xGu6pk8SEhPPQuN0FIWm1eszvWUtS/cusGCXUrlslinktoProfile/'
      },
      'cusGlobalID' => '',
      'cusGraduationDate' => '',
      'cusJOBTITLE' => '',
      'cusLink' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoQR8nTDjEp7xY55lHFPiEffYnCm8nsIW0zIvoVt0-3zrQ_GjTs/cusLink/'
      },
      'cusLink2' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoTomQPm9e3ETJ_s2pUrH5DVPZuk_Z0W41Q6y_gWBZNXq0tVd1bKDLzkB92oTy7ZdPgYWNvX/cusLink2/'
      },
      'cusMinistryCode' => '',
      'cusMinistryCodeGR' => '',
      'cusMissionHubUser' => 'Y',
      'cusMissionTripslink' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoQR8nTDjEp7xY55lHFPiEffYnCm8nsIW0zIvoVt0-3zrQ_GjTs/cusMissionTripslink/'
      },
      'cusParentAccountNumber' => '',
      'cusPrimaryAccountContactFlag' => '',
      'cusSSOGUID' => '',
      'cusSTATUS_CODE' => '',
      'cusSalutationName' => '',
      'cusSecondaryAccountContactFlag' => '',
      'cusSecondaryEmailAddress' => '',
      'domain' => 'user.com',
      'email' => 'test@user.com',
      'emailFormat' => 'unknown',
      'fax' => '',
      'firstName' => 'Test',
      'gender' => 'unknown',
      'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoQR8nTDjEp7xY55lHFPiEffYnCm8nsIW0zIvoVt0-3zrQ_GjTs',
      'isExternal' => false,
      'lastModified' => '2018-04-05 23:20:14.988Z',
      'lastName' => 'User',
      'location' => {
        'address1' => '',
        'address2' => '',
        'address3' => '',
        'address4' => '',
        'city' => '',
        'countryCode' => '',
        'stateCode' => '',
        'zipCode' => ''
      },
      'middleName' => '',
      'mobilePhone' => '',
      'phone' => '',
      'postalAddress' => {
        'addrDefined' => false,
        'addrErrorCount' => 0,
        'addrLastCheck' => '',
        'addrQuality' => '0',
        'line1' => 'Test User',
        'line2' => '',
        'line3' => '',
        'line4' => '',
        'line5' => '',
        'line6' => '',
        'serialized' => "Test User\n\n\n\n\n"
      },
      'preferredLanguage' => 'none',
      'salutation' => '',
      'subscriptions' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@EJcyhZ11jryZtasdfIAHR2c8foWIzASt5-c9p3FShoTomQPm9e3ETJ_s2pUrH5DVPZuk_Z0W41Q6y_gWBZNXq0tVd1bKDLzkB92oTy7ZdPgYWNvX/subscriptions/'
      },
      'thumbnail' => '/nl/img/thumbnails/defaultProfil.png',
      'timeZone' => 'none',
      'title' => 'Test User (test@user.com)'
    }
  end

  def adobe_campaign_subscription(campaign_name)
    {
      'PKey' => '@DD3eFh_hOTasdeUAvdK7Xkv1j3yDFslVddgKM2iVwDFotcom-nDh4vroL-1txYfv0SH1gf2U9budtwiz_Gxo7xTSf6XYruASEYp9AW1U9YxHTW8UFDz2jGGpJGgwHHXBk3Zvrw',
      'created' => '2018-04-06 19:34:44.340Z',
      'email' => '',
      'expirationDate' => '',
      'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@Ga7hAokNoLpeirz_nSoRL0CKJGFPEHwPfkxSH-6JI3i__49-4qoY-OcQnrq31JC49daKHmf9lVybo__N9gTiPaREcVIuBu794uz7cU21yq3vq7Vz/subscriptions/@DD3eFh_hOTasdeUAvdK7Xkv1j3yDFslVddgKM2iVwDFotcom-nDh4vroL-1txYfv0SH1gf2U9budtwiz_Gxo7xTSf6XYruASEYp9AW1U9YxHTW8UFDz2jGGpJGgwHHXBk3Zvrw',
      'metadata' => 'subscription',
      'mobilePhone' => '',
      'origin' => '',
      'service' => {
        'PKey' => '@EyJ3Rl7A2R7sb62mI4fNrovCP0asdIsIuoxzeN4Bhg6nW4cpbnBeIZwaJe2Dl5sdfROasd8r98XhFPVUhJBn2cqJ61SvrLZMBOK_iubDqrS0T2d_',
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/service/@EyJ3Rl7A2R7sb62mI4fNrovCP0asdIsIuoxzeN4Bhg6nW4cpbnBeIZwaJe2Dl5sdfROasd8r98XhFPVUhJBn2cqJ61SvrLZMBOK_iubDqrS0T2d_',
        'label' => 'Mission Hub Welcome Series',
        'name' => campaign_name,
        'title' => "A Really Cool Campaign (#{campaign_name})"
      },
      'serviceName' => campaign_name,
      'subscriber' => {
        'PKey' => '@Ba7hAokNoLpeirz_nSoRL0lzVcXyui_JLGHcujnlPNjYmLLGgpyTOasdM1ioH5p13eCyhkUmtCZW4ywCJQSb93F-Y5E',
        'email' => 'test@user.com',
        'firstName' => '',
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServicesExt/profile/@Ba7hAokNoLpeirz_nSoRL0lzVcXyui_JLGHcujnlPNjYmLLGgpyTOasdM1ioH5p13eCyhkUmtCZW4ywCJQSb93F-Y5E',
        'lastName' => '',
        'title' => '  (test@user.com)'
      },
      'subscriptionDate' => '',
      'title' => "Mission Hub Welcome Series (#{campaign_name}) /   (test@user.com)"
    }
  end

  def adobe_campaign(campaign_name)
    {
      'PKey' => '@AyJ3Rl7A2R7sb62mI4fNrovCP0dfyIsIuoxzeN4Bhg6QZBWQCOiscEBMIasdfUdV9cKvfXt5v5CDUtIi46s8uOP0CYPoZM1lhs4sb7gPZCcpSDKd',
      'builtIn' => false,
      'created' => '2017-03-15 12:48:26.287Z',
      'desc' => '',
      'end' => '',
      'href' => 'https://mc.adobe.io/cru/campaign/profileAndServices/service/@AyJ3Rl7A2R7sb62mI4fNrovCP0dfyIsIuoxzeN4Bhg6QZBWQCOiscEBMIasdfUdV9cKvfXt5v5CDUtIi46s8uOP0CYPoZM1lhs4sb7gPZCcpSDKd',
      'isExternal' => false,
      'isTemplate' => false,
      'label' => 'Mission Hub Welcome Series',
      'lastModified' => '2018-01-26 17:53:27.063Z',
      'limitedDuration' => false,
      'mainDate' => '2017-03-15', 'messageType' => 'email',
      'mode' => 'newsletter',
      'name' => campaign_name,
      'publicLabel' => '',
      'start' => '2017-03-15',
      'subScenarioEventType' => 'EVTNoMessageSent',
      'subscriptions' => {
        'href' => 'https://mc.adobe.io/cru/campaign/profileAndServices/service/@KyJ3Rl7A2R7sb62mI4fNrovCP0hqyIsIqwertN4Bhg6QZBWQCOiscEBMIytndUdVOdMgkFjbFDuSXRKQSewjug_1LPqU-riINCYmOCldu0kUGcTg/subscriptions/'
      },
      'targetResource' => 'profile',
      'template' => {
        'PKey' => '@Bd-IpPaCDu9kfK9pz9me5qamtpypnvidHrarzR11Q0JPNxPJuxBnuXOeFYPohiRbyfzW9vHK7MbR3ehUZu7Pp1UGm1d_5vyFdpMgobPzE5GaaNtd',
        'title' => 'Newsletter (newsletter)'
      },
      'thumbnail' => '/nl/img/thumbnails/defaultService.png',
      'title' => "Mission Hub Welcome Series (#{campaign_name}) /   (test@user.com)",
      'unsubScenarioEventType' => 'EVTNoMessageSent',
      'validityDuration' => 'P10D'
    }
  end
end
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/LineLength
