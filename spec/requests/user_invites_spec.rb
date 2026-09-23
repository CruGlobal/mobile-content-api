# frozen_string_literal: true

require "rails_helper"

describe "UserInvites management", type: :request do
  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:editor) { FactoryBot.create(:user, admin: false) }
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }

  def headers_for(user)
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  def body(attributes)
    {data: {type: "user-invite", attributes: attributes}}.to_json
  end

  let(:valid_attributes) do
    {
      "email" => "jane@partner.org",
      "given-name" => "Jane",
      "family-name" => "Smith",
      "admin" => false,
      "email-is-alias" => true,
      "grants" => {"MX" => ["*"]}
    }
  end

  describe "authorization" do
    let!(:invite) { FactoryBot.create(:user_invite) }

    it "rejects an anonymous caller on every action" do
      anon = {"Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json"}

      get "/users/invites", headers: anon
      expect(response).to have_http_status(:unauthorized)

      post "/users/invites", params: body(valid_attributes), headers: anon
      expect(response).to have_http_status(:unauthorized)

      patch "/users/invites/#{invite.id}", params: body("given-name" => "X"), headers: anon
      expect(response).to have_http_status(:unauthorized)

      delete "/users/invites/#{invite.id}", headers: anon
      expect(response).to have_http_status(:unauthorized)

      post "/users/invites/#{invite.id}/resend", headers: anon
      expect(response).to have_http_status(:unauthorized)
    end

    it "forbids a non-admin on every action" do
      get "/users/invites", headers: headers_for(editor)
      expect(response).to have_http_status(:forbidden)

      get "/users/invites/#{invite.id}", headers: headers_for(editor)
      expect(response).to have_http_status(:forbidden)

      post "/users/invites", params: body(valid_attributes), headers: headers_for(editor)
      expect(response).to have_http_status(:forbidden)

      patch "/users/invites/#{invite.id}", params: body("given-name" => "X"), headers: headers_for(editor)
      expect(response).to have_http_status(:forbidden)

      delete "/users/invites/#{invite.id}", headers: headers_for(editor)
      expect(response).to have_http_status(:forbidden)

      post "/users/invites/#{invite.id}/resend", headers: headers_for(editor)
      expect(response).to have_http_status(:forbidden)

      expect(UserInvite.count).to eq(1)
    end
  end

  describe "POST create" do
    it "creates a pending invite and returns the link" do
      post "/users/invites", params: body(valid_attributes), headers: headers_for(admin)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      attrs = json["data"]["attributes"]
      invite = UserInvite.last

      expect(json["data"]["type"]).to eq("user-invite")
      expect(attrs["email"]).to eq("jane@partner.org")
      expect(attrs["given-name"]).to eq("Jane")
      expect(attrs["family-name"]).to eq("Smith")
      expect(attrs["admin"]).to be false
      expect(attrs["email-is-alias"]).to be true
      expect(attrs["grants"]).to eq({"mx" => ["*"]})
      expect(attrs["status"]).to eq("pending")
      expect(attrs["invited-by-id"]).to eq(admin.id.to_s)
      expect(attrs["invite-url"]).to include("/invite?code=#{invite.token}")
      expect(Time.iso8601(attrs["expires-at"])).to be_within(1.minute).of(7.days.from_now)
      expect(json["meta"]).to eq({"delivered" => false, "invite-url" => invite.url})
    end

    it "is allowed for an email that already belongs to a user" do
      FactoryBot.create(:user, email: "jane@partner.org")

      post "/users/invites", params: body(valid_attributes), headers: headers_for(admin)

      expect(response).to have_http_status(:created)
    end

    it "stores language-specific grants" do
      english

      post "/users/invites", params: body(valid_attributes.merge("grants" => {"us" => ["en"], "mx" => ["*"]})), headers: headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(UserInvite.last.grants).to eq({"us" => ["en"], "mx" => ["*"]})
    end

    it "rejects an unrecognized country" do
      post "/users/invites", params: body(valid_attributes.merge("grants" => {"uk" => ["*"]})), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first["detail"]).to include("not a recognized ISO 3166-1")
      expect(UserInvite.count).to eq(0)
    end

    it "rejects an empty language list" do
      post "/users/invites", params: body(valid_attributes.merge("grants" => {"us" => []})), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first["detail"]).to include("must list at least one language code")
    end

    it "rejects an unknown language code" do
      post "/users/invites", params: body(valid_attributes.merge("grants" => {"us" => ["zz"]})), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first["detail"]).to include("Language not found for code: zz")
    end

    it "rejects a blank email" do
      post "/users/invites", params: body(valid_attributes.merge("email" => "")), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].first["source"]["pointer"]).to eq("/data/attributes/email")
    end

    it "answers 409 with the existing id when a pending invite already exists" do
      existing = FactoryBot.create(:user_invite, email: "JANE@partner.org")

      post "/users/invites", params: body(valid_attributes), headers: headers_for(admin)

      expect(response).to have_http_status(:conflict)
      error = JSON.parse(response.body)["errors"].first
      expect(error["code"]).to eq("invite_already_pending")
      expect(error["meta"]["invite-id"]).to eq(existing.id.to_s)
      expect(UserInvite.count).to eq(1)
    end

    it "allows a new invite once the earlier one was accepted" do
      FactoryBot.create(:user_invite, :accepted, email: "jane@partner.org")

      post "/users/invites", params: body(valid_attributes), headers: headers_for(admin)

      expect(response).to have_http_status(:created)
    end

    it "allows a new invite once the earlier one expired" do
      FactoryBot.create(:user_invite, :expired, email: "jane@partner.org")

      post "/users/invites", params: body(valid_attributes), headers: headers_for(admin)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET index" do
    let!(:live) { FactoryBot.create(:user_invite) }
    let!(:stale) { FactoryBot.create(:user_invite, :expired) }
    let!(:used) { FactoryBot.create(:user_invite, :accepted) }

    def ids
      JSON.parse(response.body)["data"].map { |row| row["id"] }
    end

    it "lists only pending invites by default, with the link on every row" do
      get "/users/invites", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ids).to eq([live.id.to_s])
      expect(JSON.parse(response.body)["data"].first["attributes"]["invite-url"]).to eq(live.url)
      expect(JSON.parse(response.body)["meta"]["total"]).to eq(1)
    end

    it "filters by status" do
      get "/users/invites?filter[status]=expired", headers: headers_for(admin)
      expect(ids).to eq([stale.id.to_s])

      get "/users/invites?filter[status]=accepted", headers: headers_for(admin)
      expect(ids).to eq([used.id.to_s])

      get "/users/invites?filter[status]=all", headers: headers_for(admin)
      expect(ids).to contain_exactly(live.id.to_s, stale.id.to_s, used.id.to_s)
    end

    it "treats a malformed filter as the default" do
      get "/users/invites?filter=expired", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(ids).to eq([live.id.to_s])
    end
  end

  describe "GET show" do
    it "returns the invite" do
      invite = FactoryBot.create(:user_invite)

      get "/users/invites/#{invite.id}", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(invite.id.to_s)
    end

    it "404s an unknown id" do
      get "/users/invites/0", headers: headers_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH update" do
    let!(:invite) { FactoryBot.create(:user_invite, first_name: "Before") }

    it "changes the fields it is given and keeps the token" do
      patch "/users/invites/#{invite.id}",
        params: body("given-name" => "After", "admin" => true, "grants" => {"vn" => ["*"]}),
        headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      invite.reload
      expect(invite.first_name).to eq("After")
      expect(invite.last_name).to eq("Smith")
      expect(invite.admin).to be true
      expect(invite.grants).to eq({"vn" => ["*"]})
      expect(JSON.parse(response.body)["data"]["attributes"]["token"]).to eq(invite.token)
    end

    it "rejects invalid grants without touching the invite" do
      patch "/users/invites/#{invite.id}",
        params: body("grants" => {"uk" => ["*"]}),
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(invite.reload.grants).to eq({"us" => ["*"]})
    end
  end

  describe "POST resend" do
    it "rotates the token and extends the expiry" do
      invite = FactoryBot.create(:user_invite, expires_at: 1.hour.from_now)
      old_token = invite.token

      post "/users/invites/#{invite.id}/resend", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      invite.reload
      expect(invite.token).not_to eq(old_token)
      expect(invite.expires_at).to be_within(1.minute).of(7.days.from_now)
      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["invite-url"]).to eq(invite.url)
      expect(json["meta"]["delivered"]).to be false
    end
  end

  describe "DELETE destroy" do
    it "removes the invite" do
      invite = FactoryBot.create(:user_invite)

      delete "/users/invites/#{invite.id}", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(UserInvite.exists?(invite.id)).to be false
    end

    it "404s an unknown id" do
      delete "/users/invites/0", headers: headers_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "route precedence" do
    it "still resolves users/:id for a numeric id" do
      get "/users/#{editor.id}", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["type"]).to eq("user")
    end
  end
end
