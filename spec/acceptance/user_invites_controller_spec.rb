# frozen_string_literal: true

require "acceptance_helper"

resource "UserInvitesController" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }

  get "users/invites" do
    requires_authorization

    let!(:invite) { FactoryBot.create(:user_invite) }

    it "lists pending invitations" do
      do_request

      expect(status).to eq(200)
      rows = JSON.parse(response_body)["data"]
      expect(rows.map { |row| row["id"] }).to eq([invite.id.to_s])
      expect(rows.first["attributes"]["invite-url"]).to eq(invite.url)
    end
  end

  post "users/invites" do
    requires_authorization

    let(:data) do
      {
        type: "user-invite",
        attributes: {
          "email" => "jane@partner.org",
          "given-name" => "Jane",
          "family-name" => "Smith",
          "admin" => false,
          "grants" => {"mx" => ["*"]}
        }
      }
    end

    it "creates an invitation and returns its link" do
      do_request data: data

      expect(status).to eq(201)
      json = JSON.parse(response_body)
      expect(json["data"]["attributes"]["status"]).to eq("pending")
      expect(json["meta"]["invite-url"]).to eq(UserInvite.last.url)
    end
  end

  post "users/invites/:id/resend" do
    requires_authorization

    let(:invite) { FactoryBot.create(:user_invite) }
    let(:id) { invite.id }

    it "issues a fresh token" do
      old_token = invite.token

      do_request

      expect(status).to eq(200)
      expect(invite.reload.token).not_to eq(old_token)
    end
  end

  delete "users/invites/:id" do
    requires_authorization

    let(:invite) { FactoryBot.create(:user_invite) }
    let(:id) { invite.id }

    it "revokes the invitation" do
      do_request

      expect(status).to eq(200)
      expect(UserInvite.exists?(invite.id)).to be false
    end
  end
end
