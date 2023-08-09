# frozen_string_literal: true

require "acceptance_helper"

resource "Auth" do
  include ActiveSupport::Testing::TimeHelpers

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:type) { "auth-token" }
  let(:raw_post) { params.to_json }
  let(:valid_code) { 123_456 }
  let(:valid_access_token) { "okta_access_token_definitely_a_jwt" }
  let(:user) { FactoryBot.create(:user) }

  before do
    # This is a valid p8 but revoked so that it can be put into tests here
    # We need a valid one otherwise we get "OpenSSL::PKey::ECError: invalid curve name"
    pem = <<~PEM
      -----BEGIN PRIVATE KEY-----
      MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgnomcvz1WqpTWTjOT
      +L7Pg+4opaxREy2pQk5xczt1jdWgCgYIKoZIzj0DAQehRANCAATYN61PCJoIbTq5
      2nEvzfy66BtxDNQxbP0Fvlb7rw3huEWhfCaJLEGCa4YlQbcpqc2Y9AHGIsU1jicO
      TnHJlj7w
      -----END PRIVATE KEY-----
    PEM
    ENV["APPLE_PRIVATE_KEY"] = pem
  end

  post "auth/" do
    it "create a token with valid code" do
      do_request data: {type: type, attributes: {code: valid_code}}

      expect(status).to be(201)
    end

    it "create a token with invalid code" do
      do_request data: {type: type, attributes: {code: 999_999}}

      expect(status).to be(400)
    end

    it "create a token with expired code" do
      allow(AccessCode).to(
        receive(:find_by).with(code: valid_code).and_return(AccessCode.new(expiration: DateTime.now.utc - 1.second))
      )

      do_request data: {type: type, attributes: {code: valid_code}}

      expect(status).to be(400)
    end

    context "okta" do
      it "create a token with a valid Okta access_token" do
        allow(OktaAuthService).to receive(:find_user_by_token).with(valid_access_token, nil).and_return(user)

        do_request data: {type: type, attributes: {okta_access_token: valid_access_token, create_user: nil}}

        expect(status).to be(201)
        data = JSON.parse(response_body)["data"]
        expect(data["attributes"]["user-id"]).to eq(user.id)
      end

      it "returns error with a expired Okta access_token" do
        allow(OktaAuthService).to receive(:find_user_by_token).with(valid_access_token, nil).and_raise(OktaAuthService::FailedAuthentication, "expired signature")

        do_request data: {type: type, attributes: {okta_access_token: valid_access_token, create_user: nil}}

        expect(status).to be(400)
      end

      it "handles JWT::DecodeError" do
        allow(OktaAuthService).to receive(:decode_token).with(valid_access_token).and_raise(JWT::DecodeError)

        do_request data: {type: type, attributes: {okta_access_token: valid_access_token}}
        expect(response_body.inspect).to include("JWT::DecodeError")

        expect(status).to be(400)
      end

      it "handles JWT::ExpiredSignature" do
        allow(OktaAuthService).to receive(:decode_token).with(valid_access_token).and_raise(JWT::ExpiredSignature)

        do_request data: {type: type, attributes: {okta_access_token: valid_access_token}}
        expect(response_body.inspect).to include("JWT::ExpiredSignature")

        expect(status).to be(400)
      end
    end

    context "facebook" do
      let(:type) { "auth-token-request" }

      before do
        stub_request(:get, "https://graph.facebook.com/debug_token?access_token=facebook_app_id%7Cfacebook_app_secret&input_token=authtoken")
          .to_return(status: 200, body: '{"data":{"app_id":"448969905944197","type":"USER","application":"GodTools - Dev","data_access_expires_at":1685893862,"expires_at":1683301862,"is_valid":true,"issued_at":1678117862,"metadata":{"auth_type":"rerequest","sso":"chrome_custom_tab"},"scopes":["email","openid","public_profile"],"user_id":"10158730817232041"}}')
        stub_request(:get, "https://graph.facebook.com/10158730817232041?access_token=authtoken&fields=email,id,first_name,last_name,short_name,name")
          .to_return(status: 200, body: '{"email":"daniel.frett@gmail.com","id":"10158730817232041","first_name":"Daniel","last_name":"Frett","short_name":"Daniel","name":"Daniel Frett"}')
      end

      it "creates a facebook user when it does not exists" do
        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken", create_user: true}}
        end.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq("daniel.frett@gmail.com")
        expect(user.first_name).to eq("Daniel")
        expect(user.last_name).to eq("Frett")
        expect(user.short_name).to eq("Daniel")
        expect(user.name).to eq("Daniel Frett")

        expect(status).to be(201)
        data = JSON.parse(response_body)["data"]
        expect(data["attributes"]["user-id"]).to eq(user.id)
      end

      context "when user does not exists" do
        it "passing flag 'create_user: false' it returns error 'user_not_found'" do
          expect do
            do_request data: {type: type, attributes: {facebook_access_token: "authtoken", create_user: false}}
          end.to_not change(User, :count)

          expect(status).to be(400)
          response = JSON.parse(response_body)
          expect(response["errors"][0]["code"]).to eq("user_not_found")
          expect(response["errors"][0]["detail"]).to eq("User account not found.")
        end

        it "passing flag 'create_user: true' it succeeds" do
          expect do
            do_request data: {type: type, attributes: {facebook_access_token: "authtoken", create_user: true}}
          end.to change(User, :count).by(1)

          user = User.last
          expect(user.email).to eq("daniel.frett@gmail.com")
          expect(user.first_name).to eq("Daniel")
          expect(user.last_name).to eq("Frett")
          expect(user.short_name).to eq("Daniel")
          expect(user.name).to eq("Daniel Frett")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
        end
      end

      context "when user already exists" do
        let!(:user) { FactoryBot.create(:user, facebook_user_id: "10158730817232041", email: "daniel.frett@gmail.com", first_name: "First", last_name: "Last", sso_guid: "12345") }

        it "matches an existing user and passing flag ':create_user' in 'nil' it succeeds" do
          expect do
            do_request data: {type: type, attributes: {facebook_access_token: "authtoken", create_user: nil}}
          end.to_not change(User, :count)

          user = User.last
          expect(user.email).to eq("daniel.frett@gmail.com")
          expect(user.first_name).to eq("Daniel")
          expect(user.last_name).to eq("Frett")
          expect(user.short_name).to eq("Daniel")
          expect(user.name).to eq("Daniel Frett")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
        end

        it "matches an existing user and passing flag ':create_user' in 'true' returns error code ':user_already_exists'" do
          expect do
            do_request data: {type: type, attributes: {facebook_access_token: "authtoken", create_user: true}}
          end.to_not change(User, :count)

          expect(status).to be(400)
          response = JSON.parse(response_body)
          expect(response["errors"][0]["code"]).to eq("user_already_exists")
          expect(response["errors"][0]["detail"]).to eq("User account already exists.")
        end
      end

      it "handles debug_token call fails" do
        stub_request(:get, "https://graph.facebook.com/debug_token?access_token=facebook_app_id%7Cfacebook_app_secret&input_token=authtoken")
          .to_return(status: 400, body: {"data" => {"error" => {"code" => 190, "message" => "Invalid OAuth access token - Cannot parse access token"}, "is_valid" => false, "scopes" => []}}.to_json)

        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
        end.to_not change(User, :count)

        expect(response_body).to include("Invalid OAuth access token - Cannot parse access token")
      end

      it "handles fields call fails" do
        stub_request(:get, "https://graph.facebook.com/10158730817232041?access_token=authtoken&fields=email,id,first_name,last_name,short_name,name")
          .to_return(status: 400, body: {"data" => {"error" => {"code" => 190, "message" => "Invalid OAuth access token - Cannot parse access token"}, "is_valid" => false, "scopes" => []}}.to_json)

        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
        end.to_not change(User, :count)

        expect(response_body).to include("Invalid OAuth access token - Cannot parse access token")
      end

      it "handles fields call not returning all fields" do
        stub_request(:get, "https://graph.facebook.com/10158730817232041?access_token=authtoken&fields=email,id,first_name,last_name,short_name,name")
          .to_return(status: 200, body: '{"id":"10158730817232041","first_name":"Daniel","last_name":"Frett"}')

        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
        end.to_not change(User, :count)

        expect(response_body).to include("Missing some or all user fields")
      end

      it "handles invalid token" do
        stub_request(:get, "https://graph.facebook.com/debug_token?access_token=facebook_app_id%7Cfacebook_app_secret&input_token=authtoken")
          .to_return(status: 200, body: '{"data":{"app_id":"448969905944197","type":"USER","application":"GodTools - Dev","data_access_expires_at":1685893862,"expires_at":1683301862,"is_valid":false,"issued_at":1678117862,"metadata":{"auth_type":"rerequest","sso":"chrome_custom_tab"},"scopes":["email","openid","public_profile"],"user_id":"10158730817232041"}}')

        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
        end.to_not change(User, :count)

        expect(response_body).to include("token is not valid")
      end

      it "handles json error" do
        stub_request(:get, "https://graph.facebook.com/10158730817232041?access_token=authtoken&fields=email,id,first_name,last_name,short_name,name")
          .to_return(status: 200, body: "{{{{")

        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
        end.to_not change(User, :count)

        expect(response_body).to include("unexpected token")
      end
    end
    context "google" do
      let(:type) { "auth-token-request" }
      let(:google_id_token) { "google_id_token" }
      let(:verify_oidc_response) { JSON.parse(File.read("spec/fixtures/google_token_verify_oidc_response.json")) }
      let(:google_user_id) { verify_oidc_response["sub"] }

      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(verify_oidc_response)
      end

      context "when user already exists" do
        let!(:user) { FactoryBot.create(:user, google_user_id: google_user_id) }

        it "matches an existing user and passing flag 'create_user: true' it returns error 'user_already_exists'" do
          expect do
            do_request data: {type: type, attributes: {google_id_token: google_id_token, create_user: true}}
          end.to_not change(User, :count)

          expect(status).to be(400)
          response = JSON.parse(response_body)
          expect(response["errors"][0]["code"]).to eq("user_already_exists")
          expect(response["errors"][0]["detail"]).to eq("User account already exists.")
        end

        it "matches an existing user and passing flag ':create_user' in 'nil' it succeeds" do
          expect do
            do_request data: {type: type, attributes: {google_id_token: google_id_token, create_user: nil}}
          end.to_not change(User, :count)

          user = User.last
          expect(user.email).to eq("andrewroth@gmail.com")
          expect(user.first_name).to eq("Andrew")
          expect(user.last_name).to eq("Roth")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
        end
      end

      context "when user does not exists" do
        it "passing flag 'create_user: false' it returns error 'user_not_found'" do
          expect do
            do_request data: {type: type, attributes: {google_id_token: google_id_token, create_user: false}}
          end.to_not change(User, :count)

          expect(status).to be(400)
          response = JSON.parse(response_body)
          expect(response["errors"][0]["code"]).to eq("user_not_found")
          expect(response["errors"][0]["detail"]).to eq("User account not found.")
        end

        it "passing flag 'create_user: true' it succeeds" do
          expect do
            do_request data: {type: type, attributes: {google_id_token: google_id_token, create_user: true}}
          end.to change(User, :count).by(1)

          user = User.last
          expect(user.email).to eq("andrewroth@gmail.com")
          expect(user.first_name).to eq("Andrew")
          expect(user.last_name).to eq("Roth")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
        end
      end

      it "handles token expired" do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(Google::Auth::IDTokens::ExpiredTokenError)

        expect do
          do_request data: {type: type, attributes: {google_id_token: google_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("error")
      end

      it "handles token response not having all the fields needed" do
        response = verify_oidc_response
        response.delete("sub")
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(response)

        expect do
          do_request data: {type: type, attributes: {google_id_token: google_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("error")
      end
    end

    context "apple" do
      let(:type) { "auth-token-request" }
      let(:apple_auth_code) { "auth_code" }
      let(:apple_refresh_token) { "refresh_token" }
      let(:verify_auth_code_response) { JSON.parse(File.read("spec/fixtures/apple_verify_auth_code_response.json")) }
      let(:verify_refresh_token_response) { JSON.parse(File.read("spec/fixtures/apple_verify_auth_code_response.json")) }
      let(:apple_user_id) { "001361.a5cafb7f42c845b8809c48d0f2b00889.1804" }
      let(:jwt_regex) { /^(?:[\w-]*\.){2}[\w-]*$/ } # https://stackoverflow.com/questions/61802832/regex-to-match-jwt

      before do
        stub_request(:get, "https://appleid.apple.com/auth/keys")
          .to_return(status: 200, body: File.read("spec/fixtures/apple_auth_keys.json"), headers: {content_type: "application/json"})

        stub_request(:post, "https://appleid.apple.com/auth/token")
          .with(
            body: {"client_id" => "org.cru.godtools", "client_secret" => jwt_regex, "code" => apple_auth_code, "grant_type" => "authorization_code", "redirect_uri" => "https://mobile-content-api.cru.org"}
          ).to_return(status: 200, body: verify_auth_code_response.to_json, headers: {content_type: "application/json"})

        stub_request(:post, "https://appleid.apple.com/auth/token")
          .with(
            body: {"client_id" => "org.cru.godtools", "client_secret" => jwt_regex, "refresh_token" => apple_refresh_token, "grant_type" => "refresh_token"}
          ).to_return(status: 200, body: verify_auth_code_response.to_json, headers: {content_type: "application/json"})
      end

      context "id_token verify valid" do
        before do
          allow_any_instance_of(AppleID::IdToken).to receive(:verify!).and_return(true)
        end

        it "creates a apple user when it does not exists yet" do
          expect do
            do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert", create_user: true}}
          end.to change(User, :count).by(1)

          user = User.last
          expect(user.email).to eq("levi.eggert@gmail.com")
          expect(user.first_name).to eq("Levi")
          expect(user.last_name).to eq("Eggert")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
          expect(data["attributes"]["token"]).to match(jwt_regex)
          expect(data["attributes"]["apple-refresh-token"]).to eq(verify_auth_code_response["refresh_token"])
        end

        context "when user does not exists" do
          it "passing flag 'create_user: false' it returns error 'user_not_found'" do
            expect do
              do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert", create_user: false}}
            end.to change(User, :count).by(0)

            expect(status).to be(400)
            response = JSON.parse(response_body)
            expect(response["errors"][0]["code"]).to eq("user_not_found")
            expect(response["errors"][0]["detail"]).to eq("User account not found.")
          end
        end

        context "when user already exists" do
          let!(:user) { FactoryBot.create(:user, apple_user_id: apple_user_id, first_name: "Levi", last_name: "Eggert") }

          it "matches an existing user and passing flag 'create_user: true' it returns error 'user_already_exists'" do
            FactoryBot.create(:user, email: "levi.eggert@gmail.com", apple_user_id: "001361.a5cafb7f42c845b8809c48d0f2b00889.1804")

            expect do
              do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert", create_user: true}}
            end.to change(User, :count).by(0)

            expect(status).to be(400)
            response = JSON.parse(response_body)
            expect(response["errors"][0]["code"]).to eq("user_already_exists")
            expect(response["errors"][0]["detail"]).to eq("User account already exists.")
          end

          it "matches an existing user and passing flag ':create_user' in 'nil' it succeeds" do
            expect do
              do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert", create_user: nil}}
            end.to change(User, :count).by(0)

            user = User.last
            expect(user.email).to eq("levi.eggert@gmail.com")
            expect(user.first_name).to eq("Levi")
            expect(user.last_name).to eq("Eggert")

            expect(status).to be(201)
            data = JSON.parse(response_body)["data"]
            expect(data["attributes"]["user-id"]).to eq(user.id)
            expect(data["attributes"]["token"]).to match(jwt_regex)
            expect(data["attributes"]["apple-refresh-token"]).to eq(verify_auth_code_response["refresh_token"])
          end

          it "auth code matches an existing user" do
            expect do
              do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code}}
            end.to_not change(User, :count)

            user.reload
            expect(user.email).to eq("levi.eggert@gmail.com")
            expect(user.first_name).to eq("Levi")
            expect(user.last_name).to eq("Eggert")

            expect(status).to be(201)
            data = JSON.parse(response_body)["data"]
            expect(data["attributes"]["user-id"]).to eq(user.id)
            expect(data["attributes"]["token"]).to match(jwt_regex)
            expect(data["attributes"]["apple-refresh-token"]).to eq(verify_auth_code_response["refresh_token"])
          end

          it "refresh token matches an existing user" do
            expect do
              do_request data: {type: type, attributes: {apple_refresh_token: apple_refresh_token, create_user: true}}
            end.to_not change(User, :count)

            user.reload
            expect(user.email).to eq("levi.eggert@gmail.com")
            expect(user.first_name).to eq("Levi")
            expect(user.last_name).to eq("Eggert")

            expect(status).to be(201)
            data = JSON.parse(response_body)["data"]
            expect(data["attributes"]["user-id"]).to eq(user.id)
            expect(data["attributes"]["token"]).to match(jwt_regex)
            expect(data["attributes"]["apple-refresh-token"]).to be_nil
          end
        end
      end

      it "handles invalid json" do
        stub_request(:post, "https://appleid.apple.com/auth/token")
          .with(
            body: {"client_id" => "org.cru.godtools", "client_secret" => jwt_regex, "code" => apple_auth_code, "grant_type" => "authorization_code", "redirect_uri" => "https://mobile-content-api.cru.org"}
          ).to_return(status: 200, body: "INVALID JSON", headers: {"Content-Type" => "application/json"})

        expect do
          do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert"}}
        end.to_not change(User, :count)

        expect(response_body.inspect).to include("Faraday::ParsingError")
        expect(status).to be(400)
      end

      it "handles verification failure" do
        stub_request(:get, "https://appleid.apple.com/auth/keys")
          .to_return(status: 200, body: "invalid keys")

        expect do
          do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert"}}
        end.to_not change(User, :count)

        expect(response_body.inspect).to include("error")
        expect(status).to be(400)
      end

      context "client error" do
        let(:apple_id_client) { double("applie_id_client") }

        before do
          allow_any_instance_of(AppleID::IdToken).to receive(:verify!).and_raise(AppleID::Client::Error.new(500, {error_description: "something"}))
        end

        it "handles client error" do
          expect do
            do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert"}}
          end.to_not change(User, :count)

          expect(response_body.inspect).to include("AppleID::Client::Error")
          expect(status).to be(400)
        end

        it "does not include apple env vars when rails env is production" do
          allow(Rails).to receive(:env) { "production".inquiry }
          ENV["SECRET_KEY_BASE"] = "secret"

          expect do
            do_request data: {type: type, attributes: {apple_auth_code: apple_auth_code, apple_given_name: "Levi", apple_family_name: "Eggert"}}
          end.to_not change(User, :count)

          expect(response_body.inspect).to include("AppleID::Client::Error")
          expect(response_body.inspect).to_not include("private_key")
          expect(status).to be(400)
        end
      end
    end
  end
end
