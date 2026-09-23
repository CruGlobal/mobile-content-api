# frozen_string_literal: true

require "rails_helper"

describe "UserInvite acceptance", type: :request do
  let(:user) { FactoryBot.create(:user, admin: false) }
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }
  let(:spanish) { Language.find_or_create_by!(code: "es") { |l| l.name = "Spanish" } }
  let(:path) { "/users/me/accept-invite" }

  def headers_for(user)
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  def accept(token, as: user)
    post path, params: {data: {attributes: {token: token}}}.to_json, headers: headers_for(as)
  end

  it "rejects an anonymous caller" do
    invite = FactoryBot.create(:user_invite)

    post path,
      params: {data: {attributes: {token: invite.token}}}.to_json,
      headers: {"Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json"}

    expect(response).to have_http_status(:unauthorized)
    expect(invite.reload).to be_pending
  end

  it "requires a token" do
    accept("")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "applies the grants and answers with the refreshed user" do
    spanish
    invite = FactoryBot.create(:user_invite, grants: {"mx" => ["es"]})

    accept(invite.token)

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["data"]["type"]).to eq("user")
    expect(json["data"]["id"]).to eq(user.id.to_s)
    expect(json["data"]["attributes"]["resource-score-grants"]).to eq({"mx" => ["es"]})
    expect(json["meta"]).to eq({"accepted-invite-id" => invite.id.to_s, "skipped-grants" => []})

    invite.reload
    expect(invite).to be_accepted
    expect(invite.accepted_by).to eq(user)
  end

  it "is additive: a pre-existing grant survives" do
    FactoryBot.create(:resource_score_permission, user: user, country: "us", language: english)
    invite = FactoryBot.create(:user_invite, grants: {"mx" => ["*"]})

    accept(invite.token)

    expect(response).to have_http_status(:ok)
    expect(user.resource_score_grants).to eq({"us" => ["en"], "mx" => ["*"]})
  end

  it "is idempotent for a grant the user already holds" do
    FactoryBot.create(:resource_score_permission, :all_languages, user: user, country: "us")
    invite = FactoryBot.create(:user_invite, grants: {"us" => ["*"]})

    expect { accept(invite.token) }.not_to change { user.resource_score_permissions.count }
    expect(response).to have_http_status(:ok)
  end

  it "does not require the invite email to match the login email" do
    invite = FactoryBot.create(:user_invite, email: "alias@partner.org")

    accept(invite.token)

    expect(response).to have_http_status(:ok)
    expect(user.resource_score_grants).to eq({"us" => ["*"]})
  end

  it "promotes to admin when the invite says so" do
    invite = FactoryBot.create(:user_invite, :superadmin)

    accept(invite.token)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["data"]["attributes"]["admin"]).to be true
    expect(user.reload.admin).to be true
  end

  it "never demotes an existing admin" do
    admin = FactoryBot.create(:user, admin: true)
    invite = FactoryBot.create(:user_invite, admin: false)

    accept(invite.token, as: admin)

    expect(response).to have_http_status(:ok)
    expect(admin.reload.admin).to be true
  end

  it "refuses a second use of the same token" do
    invite = FactoryBot.create(:user_invite)
    accept(invite.token)
    other = FactoryBot.create(:user)

    accept(invite.token, as: other)

    expect(response).to have_http_status(:conflict)
    expect(JSON.parse(response.body)["errors"].first["code"]).to eq("invite_already_accepted")
    expect(other.resource_score_permissions).to be_empty
  end

  it "refuses an expired invite" do
    invite = FactoryBot.create(:user_invite, :expired)

    accept(invite.token)

    expect(response).to have_http_status(:gone)
    expect(JSON.parse(response.body)["errors"].first["code"]).to eq("invite_expired")
    expect(user.resource_score_permissions).to be_empty
  end

  it "404s an unknown token" do
    accept("not-a-real-token")

    expect(response).to have_http_status(:not_found)
    expect(JSON.parse(response.body)["errors"].first["code"]).to eq("invite_not_found")
  end

  it "reports a language that disappeared after the invite was created" do
    invite = FactoryBot.create(:user_invite, grants: {"mx" => ["*"]})
    invite.update_column(:grants, {"us" => ["zz"], "mx" => ["*"]})

    accept(invite.token)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["meta"]["skipped-grants"]).to eq(["us/zz"])
    expect(user.resource_score_grants).to eq({"mx" => ["*"]})
  end

  it "does not let an old token work after a resend" do
    invite = FactoryBot.create(:user_invite)
    old_token = invite.token
    invite.resend!

    accept(old_token)

    expect(response).to have_http_status(:not_found)

    accept(invite.token)

    expect(response).to have_http_status(:ok)
  end
end
