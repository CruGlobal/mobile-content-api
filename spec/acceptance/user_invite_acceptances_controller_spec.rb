# frozen_string_literal: true

require "acceptance_helper"

resource "UserInviteAcceptancesController" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }

  post "users/me/accept-invite" do
    # requires_okta_login expects the group to own the user, as the other
    # acceptance specs do; it only sets the header.
    let(:user) { FactoryBot.create(:user, admin: false) }
    requires_okta_login

    let(:invite) { FactoryBot.create(:user_invite, grants: {"mx" => ["*"]}) }
    let(:data) { {attributes: {token: invite.token}} }

    it "merges the invitation's grants into the caller and returns the user" do
      do_request data: data

      expect(status).to eq(200)
      json = JSON.parse(response_body)
      expect(json["data"]["type"]).to eq("user")
      expect(json["data"]["attributes"]["resource-score-grants"]).to eq({"mx" => ["*"]})
      expect(json["meta"]["accepted-invite-id"]).to eq(invite.id.to_s)
      expect(invite.reload.accepted_by).to eq(user)
    end
  end
end
