Rails.application.config.to_prepare do
  if Rails.env.in?(["production", "staging"]) &&
      ENV["AWS_S3_CONFIG_BUCKET"].present? &&
      !File.exist?(UpdateGlobalActivityAnalytics::SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH)
    s3_client = Aws::S3::Client.new
    s3_client.get_object(bucket: ENV["AWS_S3_CONFIG_BUCKET"],
      key: "credentials.json", # remote file name
      response_target: UpdateGlobalActivityAnalytics::SERVICE_ACCOUNT_CREDENTIALS_FILE_PATH)
  end
end
