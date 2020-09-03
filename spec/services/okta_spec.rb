require "rails_helper"
require "json/jwt"

RSpec.describe Okta do
  let(:okta_user_info) do
    {
      sub: "qwer",
      email: "okta@okta.com",
      first_name: "Okta",
      lsat_name: "Test"
    }
  end
  let(:jwt_payload) { okta_user_info.merge(exp: 1.minute.from_now.to_i) }
  let(:jwt_default_payload) { {iss: ENV["OKTA_SERVER_PATH"], aud: ENV["OKTA_SERVER_AUDIENCE"]} }
  let(:rsa_private) { OpenSSL::PKey::RSA.generate 2048 }
  let(:jwk) { rsa_private.to_jwk }
  let(:jwk_json) { {keys: [jwk]}.to_json }
  let(:id_token) { JWT.encode(jwt_default_payload.merge(jwt_payload), rsa_private, "RS256", kid: jwk[:kid]) }

  before { stub_request(:get, "https://dev1-signon.okta.com/oauth2/v1/keys").to_return(body: jwk_json) }

  describe ".find_user_by_id_token" do
    it "return a newly User" do
      expect {
        expect(described_class.find_user_by_id_token(id_token)).to be_a User
      }.to change(User, :count).by(1)
    end

    context "with existing user" do
      let!(:user) { FactoryBot.create(:user, okta_id: "qwer") }

      it "returns existing user" do
        expect {
          expect(described_class.find_user_by_id_token(id_token)).to eq user
        }.to change(User, :count).by(0)
      end
    end

    context "with expired token" do
      let(:jwt_payload) { okta_user_info.merge(exp: 1.minute.ago.to_i) }

      it "raises error" do
        expect { described_class.find_user_by_id_token(id_token) }.to raise_error Okta::FailedAuthentication
      end

      it "does not create a user" do
        # try remove this disable after https://github.com/CruGlobal/mobile-content-api/pull/468 merges
        # rubocop:disable Standard/SemanticBlocks
        expect do
          described_class.find_user_by_id_token(id_token)
        rescue Okta::FailedAuthentication
          nil
        end.to change(User, :count).by(0)
        # rubocop:enable Standard/SemanticBlocks
      end
    end
  end
end
