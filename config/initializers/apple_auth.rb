AppleAuth.configure do |config|
  config.apple_client_id = ENV.fetch("APPLE_CLIENT_ID")
end
