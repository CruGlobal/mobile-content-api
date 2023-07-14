# frozen_string_literal: true

require "acceptance_helper"

resource "DeletionRequests" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let!(:user) { FactoryBot.create(:user, facebook_user_id: "12345") }

  post "account/deletion_requests/facebook" do
    let!(:other_user) { FactoryBot.create(:user, facebook_user_id: "12346") }

    it "create deletion request" do
      data = {"user_id" => 12345}
      payload = Base64.urlsafe_encode64(data.to_json)
      encoded = OpenSSL::HMAC.digest("SHA256", ENV["FACEBOOK_APP_SECRET"], payload)

      # it seems this isn't getting set from the default_url_options line in config/environments/test.rb
      DeletionRequestsController.default_url_options = Rails.application.routes.default_url_options

      expect {
        expect {
          do_request({signed_request: "#{Base64.urlsafe_encode64(encoded)}.#{payload}"})
        }.to change { User.count }.by(-1)
      }.to change { DeletionRequest.count }.by(1)

      response = JSON.parse(response_body)
      expect(response["url"]).to eq(Rails.application.routes.url_helpers.deletion_request_url(DeletionRequest.last.pid, host: Rails.application.routes.default_url_options[:host]))
      expect(response["confirmation_code"]).to eq(DeletionRequest.last.pid)
    end

    it "fails if encoding does not match" do
      data = {"user_id" => 12345}
      payload = Base64.urlsafe_encode64(data.to_json)
      encoded = "INVALID"

      # it seems this isn't getting set from the default_url_options line in config/environments/test.rb
      DeletionRequestsController.default_url_options = Rails.application.routes.default_url_options

      expect {
        expect {
          do_request({signed_request: "#{Base64.urlsafe_encode64(encoded)}.#{payload}"})
        }.to_not change { User.count }
      }.to_not change { DeletionRequest.count }

      expect(JSON.parse(response_body)).to eq("error" => "FB deletion callback called with invalid data")
    end
  end

  get "account/deletion_requests/:id" do
    let!(:deletion_request) { FactoryBot.create(:deletion_request, provider: "facebook", uid: "1", pid: "public_id") }
    let(:id) { "public_id" }

    it "returns that the deletion request is completed" do
      do_request
      expect(JSON.parse(response_body)).to eq("data" => "Your data has been completely deleted")
    end

    context "user still present" do
      let!(:user) { FactoryBot.create(:user, facebook_user_id: "1") }

      it "returns that the deletion request is completed" do
        do_request
        expect(JSON.parse(response_body)).to eq("data" => "Your deletion request is still in progress")
      end
    end
  end
end
