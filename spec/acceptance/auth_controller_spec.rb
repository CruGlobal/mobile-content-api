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

    it "create a token with a valid Okta access_token" do
      allow(Okta).to receive(:find_user_by_access_token).with(valid_access_token).and_return(user)

      do_request data: {type: type, attributes: {okta_access_token: valid_access_token}}

      expect(status).to be(201)
      data = JSON.parse(response_body)["data"]
      expect(data["attributes"]["user-id"]).to eq(user.id)
    end

    it "returns error with a expired Okta access_token" do
      allow(Okta).to receive(:find_user_by_access_token).with(valid_access_token).and_raise(Okta::FailedAuthentication, "expired signature")

      do_request data: {type: type, attributes: {okta_access_token: valid_access_token}}

      expect(status).to be(400)
    end

    context "facebook" do
      let(:type) { "auth-token-request" }

      before do
        stub_request(:get, "https://graph.facebook.com/debug_token?access_token=facebook_app_id%7Cfacebook_app_secret&input_token=authtoken")
          .to_return(status: 200, body: '{"data":{"app_id":"448969905944197","type":"USER","application":"GodTools - Dev","data_access_expires_at":1685893862,"expires_at":1683301862,"is_valid":true,"issued_at":1678117862,"metadata":{"auth_type":"rerequest","sso":"chrome_custom_tab"},"scopes":["email","openid","public_profile"],"user_id":"10158730817232041"}}')
        stub_request(:get, "https://graph.facebook.com/10158730817232041?access_token=authtoken&fields=email,id,first_name,last_name,short_name,name")
          .to_return(status: 200, body: '{"email":"daniel.frett@gmail.com","id":"10158730817232041","first_name":"Daniel","last_name":"Frett","short_name":"Daniel","name":"Daniel Frett"}')
      end

      it "creates a facebook user" do
        expect do
          do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
          puts response_body.inspect
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

      context "user already exists" do
        let!(:user) { FactoryBot.create(:user, facebook_user_id: "10158730817232041", email: "daniel.frett@gmail.com", first_name: "First", last_name: "Last", sso_guid: "12345") }

        it "matches an existing user" do
          expect do
            do_request data: {type: type, attributes: {facebook_access_token: "authtoken"}}
          end.to_not change(User, :count)

          user.reload
          expect(user.email).to eq("daniel.frett@gmail.com")
          expect(user.first_name).to eq("Daniel")
          expect(user.last_name).to eq("Frett")
          expect(user.short_name).to eq("Daniel")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
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

      it "creates a google user" do
        expect do
          do_request data: {type: type, attributes: {google_access_token: google_id_token}}
        end.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq("andrewroth@gmail.com")
        expect(user.first_name).to eq("Andrew")
        expect(user.last_name).to eq("Roth")

        expect(status).to be(201)
        data = JSON.parse(response_body)["data"]
        expect(data["attributes"]["user-id"]).to eq(user.id)
      end

      context "user already exists" do
        let!(:user) { FactoryBot.create(:user, google_user_id: google_user_id) }

        it "matches an existing user" do
          expect do
            do_request data: {type: type, attributes: {google_access_token: google_id_token}}
          end.to_not change(User, :count)

          user.reload
          expect(user.email).to eq("andrewroth@gmail.com")
          expect(user.first_name).to eq("Andrew")
          expect(user.last_name).to eq("Roth")
          expect(user.name).to eq("Andrew Roth")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
        end
      end

      it "handles token expired" do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(Google::Auth::IDTokens::ExpiredTokenError)

        expect do
          do_request data: {type: type, attributes: {google_access_token: google_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("error")
      end

      it "handles token response not having all the fields needed" do
        response = verify_oidc_response
        response.delete("sub")
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(response)

        expect do
          do_request data: {type: type, attributes: {google_access_token: google_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("error")
      end
    end

    context "apple" do
      let(:type) { "auth-token-request" }
      let(:apple_id_token) { "auth_id_token" }
      let(:token_decode_response) { JSON.parse(File.read("spec/fixtures/apple_token_decode_response.json") % { exp: 2.hours.from_now.to_i, iat: 1.hour.ago.to_i } ) }
      let(:apple_user_id) { token_decode_response["sub"] }
      let(:jwt_decoder) { AppleAuth::JWTDecoder.new(apple_id_token) }

      before do
        allow(AppleAuth::JWTDecoder).to receive(:new).and_return(jwt_decoder)
        allow(jwt_decoder).to receive(:call).and_return(token_decode_response)
      end

      it "creates a apple user" do
        expect do
          do_request data: {type: type, attributes: {apple_access_token: apple_id_token, apple_given_name: "Levi", apple_family_name: "Eggert"}}
        end.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq("levi.eggert@gmail.com")
        expect(user.first_name).to eq("Levi")
        expect(user.last_name).to eq("Eggert")

        expect(status).to be(201)
        data = JSON.parse(response_body)["data"]
        expect(data["attributes"]["user-id"]).to eq(user.id)
      end

      context "user already exists" do
        let!(:user) { FactoryBot.create(:user, apple_user_id: apple_user_id, first_name: "Levi", last_name: "Eggert") }

        it "matches an existing user" do
          expect do
            do_request data: {type: type, attributes: {apple_access_token: apple_id_token}}
          end.to_not change(User, :count)

          user.reload
          expect(user.email).to eq("levi.eggert@gmail.com")
          expect(user.first_name).to eq("Levi")
          expect(user.last_name).to eq("Eggert")

          expect(status).to be(201)
          data = JSON.parse(response_body)["data"]
          expect(data["attributes"]["user-id"]).to eq(user.id)
        end
      end

      it "handles token expired" do
        allow(jwt_decoder).to receive(:call).and_raise(JWT::ExpiredSignature)

        expect do
          do_request data: {type: type, attributes: {apple_access_token: apple_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("error")
      end

      it "handles token response not having all the fields needed" do
        response = token_decode_response.delete("sub")
        allow(jwt_decoder).to receive(:call).and_return(response)

        expect do
          do_request data: {type: type, attributes: {apple_access_token: apple_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("error")
      end
      it "checks iss in token" do
        response = token_decode_response
        response["iss"] = "https://some.other.issuer"
        allow(jwt_decoder).to receive(:call).and_return(response)

        expect do
          do_request data: {type: type, attributes: {apple_access_token: apple_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("jwt_iss is different to apple_iss")
      end
      it "checks aud in token" do
        response = token_decode_response
        response["aud"] = "some.other.org"
        allow(jwt_decoder).to receive(:call).and_return(response)

        expect do
          do_request data: {type: type, attributes: {apple_access_token: apple_id_token}}
        end.to_not change(User, :count)

        expect(response_body).to include("jwt_aud is different to apple_client_id")
      end
    end
  end
end
