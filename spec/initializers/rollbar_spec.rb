require "rails_helper"

RSpec.describe "Rollbar's request extraction" do
  let(:masked) { a_string_matching(/\A\*+\z/) }
  let(:fake_values) { [] }
  let(:filter_list_names) { %i[passw secret token _key crypt salt certificate otp ssn cvv cvc] }

  def fake(label)
    "fake-#{label}-123".tap { |value| fake_values << value }
  end

  def request_data_rollbar_would_send(env)
    env["action_dispatch.parameter_filter"] = Rails.application.env_config["action_dispatch.parameter_filter"]
    Class.new { include Rollbar::RequestDataExtractor }.new.extract_request_data_from_rack(env)
  end

  def expect_no_fake_values_in(data)
    json = data.to_json
    fake_values.each { |value| expect(json).not_to include(value) }
  end

  it "masks every name on the filter list when posted" do
    params = filter_list_names.index_with { |name| fake(name) }
    env = Rack::MockRequest.env_for("/", method: "POST", params: params)

    data = request_data_rollbar_would_send(env)

    expect(data[:POST].keys).to match_array(filter_list_names.map(&:to_s))
    expect(data[:POST].values).to all(masked)
    expect_no_fake_values_in(data)
  end

  it "masks the sign-in tokens in a JSON:API body, with dashed or underscored names, and keeps the rest" do
    attributes = {
      "apple_refresh_token" => fake("apple-refresh-token"),
      "google-id-token" => fake("google-id-token"),
      "okta_access_token" => fake("okta-access-token"),
      "facebook-id-token" => fake("facebook-id-token"),
      "facebook_access_token" => fake("facebook-access-token"),
      "create_user" => true
    }
    body = {data: {type: "auth-token-request", attributes: attributes}}.to_json
    env = Rack::MockRequest.env_for("/auth", :method => "POST", :input => body, "CONTENT_TYPE" => "application/vnd.api+json")

    data = request_data_rollbar_would_send(env)

    sent = JSON.parse(data[:body]).dig("data", "attributes")
    expect(sent.except("create_user").values).to all(masked)
    expect(sent["create_user"]).to be(true)
    expect_no_fake_values_in(data)
  end

  it "masks the invite token a user accepts with" do
    body = {data: {type: "user-invite-acceptance", attributes: {token: fake("invite-token")}}}.to_json
    env = Rack::MockRequest.env_for("/users/me/accept-invite", :method => "POST", :input => body, "CONTENT_TYPE" => "application/vnd.api+json")

    data = request_data_rollbar_would_send(env)

    expect(JSON.parse(data[:body]).dig("data", "attributes", "token")).to match(masked)
    expect_no_fake_values_in(data)
  end

  it "masks the session cookie and keeps ordinary cookies" do
    cookie_name = Rails.application.config.session_options[:key]
    env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "#{cookie_name}=#{fake("session-cookie")}; _ga=GA1.2.3")

    data = request_data_rollbar_would_send(env)

    expect(data[:cookies]).to match(cookie_name => masked, "_ga" => "GA1.2.3")
    expect_no_fake_values_in(data)
  end

  it "masks the Authorization header and the Referer" do
    env = Rack::MockRequest.env_for(
      "/",
      "HTTP_AUTHORIZATION" => fake("auth-token"),
      "HTTP_REFERER" => "https://example.com/invite?token=#{fake("referer-token")}"
    )

    data = request_data_rollbar_would_send(env)

    expect(data[:headers]).to include("Authorization" => masked, "Referer" => masked)
    expect_no_fake_values_in(data)
  end
end
