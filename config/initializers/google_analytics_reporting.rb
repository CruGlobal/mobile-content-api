# frozen_string_literal: true

Rails.application.config.to_prepare do                                # !!!!!! Following adobe.rb format??? !!!!!!!!
  # Create a Google Analytics Reporting service
  service = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new

  # Create service account credentials
  credentials = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('config/initializers/service_account_cred.json'),      # !!!!!!!! DO WE USE ENV VARIABLE HERE??? !!!!!!!!!
    scope: 'https://www.googleapis.com/auth/analytics.readonly'
  )

  # Authorize with our readonly credentials
  service.authorization = credentials

  $google_client = service

  # MobileContent::GoogleClient.setup
end