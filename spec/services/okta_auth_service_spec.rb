require "rails_helper"

RSpec.describe OktaAuthService do
  let(:okta_user_info) do
    {
      ssoguid: "qwer",
      email: "okta@okta.com",
      first_name: "Okta",
      last_name: "Test",
      name: "Okta Test"
    }
  end

  let(:jwt_payload) { {exp: 1.minute.from_now.to_i} }
  let(:okta_client_id) { ENV["OKTA_SERVER_AUDIENCE"].split(",").first }
  let(:jwt_default_payload) { {iss: ENV["OKTA_SERVER_PATH"], aud: ENV["OKTA_SERVER_PATH"], cid: okta_client_id} }
  let(:access_token) { JWT.encode(jwt_default_payload.merge(jwt_payload), nil, "none") }

  def stub_successful_profile
    stub_request(:get, "https://dev1-signon.okta.com/oauth2/v1/userinfo")
      .with(headers: {Authorization: "Bearer #{access_token}"})
      .to_return(body: okta_user_info.to_json)
  end

  def stub_unsuccessful_profile
    stub_request(:get, "https://dev1-signon.okta.com/oauth2/v1/userinfo").to_return(status: 401)
  end

  describe ".find_user_by_token" do
    it "return a newly User" do
      stub_successful_profile

      expect {
        expect(described_class.find_user_by_token(access_token)).to be_a User
      }.to change(User, :count).by(1)
    end

    context "with existing user" do
      let!(:user) { FactoryBot.create(:user, sso_guid: "qwer") }

      before { stub_successful_profile }

      it "returns existing user" do
        expect {
          expect(described_class.find_user_by_token(access_token)).to eq user
        }.to change(User, :count).by(0)
      end
    end

    context "with expired token" do
      let(:jwt_payload) { {exp: 1.minute.ago.to_i} }

      it "raises error" do
        expect { described_class.find_user_by_token(access_token) }.to raise_error OktaAuthService::FailedAuthentication
      end

      it "does not create a user" do
        expect {
          begin
            described_class.find_user_by_token(access_token)
          rescue OktaAuthService::FailedAuthentication
            nil
          end
        }.to change(User, :count).by(0)
      end
    end

    context "invalid ticket signing" do
      before { stub_unsuccessful_profile }

      describe "#validate" do
        it "raises an authentication error with a message" do
          expect { described_class.find_user_by_token(access_token) }.to(
            raise_error(
              OktaAuthService::FailedAuthentication,
              "Error validating access_token with Okta"
            )
          )
        end
      end
    end

    context "cid" do
      let(:jwt_default_payload) { {iss: ENV["OKTA_SERVER_PATH"], aud: ENV["OKTA_SERVER_PATH"], cid: "other"} }

      it "raises an authentication method when validation fails" do
        expect { described_class.find_user_by_token(access_token) }.to(
          raise_error(
            OktaAuthService::FailedAuthentication,
            "Invalid access_token cid."
          )
        )
      end
    end
    context "iss" do
      let(:jwt_default_payload) { {iss: "other", aud: ENV["OKTA_SERVER_PATH"], cid: okta_client_id} }

      it "raises an authentication method when validation fails" do
        expect { described_class.find_user_by_token(access_token) }.to(
          raise_error(
            OktaAuthService::FailedAuthentication,
            "Invalid issuer. Expected https://dev1-signon.okta.com, received other"
          )
        )
      end
    end
    context "extract_user_atts" do
      let(:okta_user_info) do
        {
          email: "okta@okta.com",
          first_name: "Okta",
          last_name: "Test",
          name: "Okta Test"
        }
      end

      it "checks ssoguid is present" do
        stub_successful_profile
        expect { described_class.find_user_by_token(access_token) }.to(
          raise_error(
            OktaAuthService::FailedAuthentication,
            "Access Token does not include sso guid, make sure login scope includes profile"
          )
        )
      end
    end
  end
end
