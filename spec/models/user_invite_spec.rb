# frozen_string_literal: true

require "rails_helper"

describe UserInvite do
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }
  let(:spanish) { Language.find_or_create_by!(code: "es") { |l| l.name = "Spanish" } }

  describe "creation" do
    it "generates a token and a seven-day expiry" do
      invite = FactoryBot.create(:user_invite)

      expect(invite.token).to be_present
      expect(invite.token.length).to eq(UserInvite::TOKEN_LENGTH)
      expect(invite.expires_at).to be_within(1.minute).of(7.days.from_now)
      expect(invite).to be_pending
    end

    it "keeps an explicit expiry" do
      invite = FactoryBot.create(:user_invite, expires_at: 1.day.from_now)

      expect(invite.expires_at).to be_within(1.minute).of(1.day.from_now)
    end

    it "builds the link from the configured admin origin" do
      invite = FactoryBot.create(:user_invite)

      expect(invite.url).to eq("#{Rails.configuration.x.admin_app_base_url}/invite?code=#{invite.token}")
    end

    it "requires a well-formed email" do
      expect(FactoryBot.build(:user_invite, email: "")).not_to be_valid
      expect(FactoryBot.build(:user_invite, email: "not-an-email")).not_to be_valid
    end

    it "rejects an unrecognized country at invite time" do
      invite = FactoryBot.build(:user_invite, grants: {"uk" => ["*"]})

      expect(invite).not_to be_valid
      expect(invite.errors[:grants].first).to include("not a recognized ISO 3166-1")
    end

    it "rejects an unknown language code" do
      invite = FactoryBot.build(:user_invite, grants: {"us" => ["zz"]})

      expect(invite).not_to be_valid
      expect(invite.errors[:grants].first).to include("Language not found for code: zz")
    end

    it "rejects an empty language list" do
      invite = FactoryBot.build(:user_invite, grants: {"us" => []})

      expect(invite).not_to be_valid
      expect(invite.errors[:grants].first).to include("must list at least one language code")
    end

    it "rejects a grants value that is not a map" do
      invite = FactoryBot.build(:user_invite, grants: ["us"])

      expect(invite).not_to be_valid
    end

    it "accepts real language codes" do
      english
      invite = FactoryBot.build(:user_invite, grants: {"us" => ["en", "*"]})

      expect(invite).to be_valid
    end

    it "allows only one pending invite per email, case-insensitively" do
      FactoryBot.create(:user_invite, email: "Jane@Partner.org")
      duplicate = FactoryBot.build(:user_invite, email: "jane@partner.org")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("already has a pending invitation")
    end

    it "allows a new invite once the previous one expired or was accepted" do
      FactoryBot.create(:user_invite, :expired, email: "a@partner.org")
      FactoryBot.create(:user_invite, :accepted, email: "b@partner.org")

      expect(FactoryBot.build(:user_invite, email: "a@partner.org")).to be_valid
      expect(FactoryBot.build(:user_invite, email: "b@partner.org")).to be_valid
    end
  end

  describe "scopes and status" do
    let!(:live) { FactoryBot.create(:user_invite) }
    let!(:stale) { FactoryBot.create(:user_invite, :expired) }
    let!(:used) { FactoryBot.create(:user_invite, :accepted) }

    it "partitions invites" do
      expect(UserInvite.pending).to contain_exactly(live)
      expect(UserInvite.expired).to contain_exactly(stale)
      expect(UserInvite.accepted).to contain_exactly(used)
    end

    it "reports a status string" do
      expect(live.status).to eq("pending")
      expect(stale.status).to eq("expired")
      expect(used.status).to eq("accepted")
    end

    it "treats an accepted-then-expired invite as accepted, not expired" do
      used.update!(expires_at: 1.day.ago)

      expect(used.status).to eq("accepted")
      expect(UserInvite.expired).not_to include(used)
    end
  end

  describe "#resend!" do
    it "rotates the token and restarts the clock" do
      invite = FactoryBot.create(:user_invite, expires_at: 1.hour.from_now)
      old_token = invite.token

      invite.resend!

      expect(invite.token).not_to eq(old_token)
      expect(invite.expires_at).to be_within(1.minute).of(7.days.from_now)
    end
  end

  describe "#accept!" do
    let(:user) { FactoryBot.create(:user) }

    it "adds the grants, stamps the acceptor and marks the invite used" do
      spanish
      invite = FactoryBot.create(:user_invite, grants: {"mx" => ["es"], "vn" => ["*"]})

      skipped = invite.accept!(user)

      expect(skipped).to eq([])
      expect(user.resource_score_grants).to eq({"mx" => ["es"], "vn" => ["*"]})
      expect(invite.reload).to be_accepted
      expect(invite.accepted_by).to eq(user)
      expect(invite.accepted_at).to be_within(1.minute).of(Time.current)
    end

    it "is additive: existing grants survive" do
      FactoryBot.create(:resource_score_permission, user: user, country: "us", language: english)
      invite = FactoryBot.create(:user_invite, grants: {"mx" => ["*"]})

      invite.accept!(user)

      expect(user.resource_score_grants).to eq({"us" => ["en"], "mx" => ["*"]})
    end

    it "is a no-op for a grant the user already holds" do
      FactoryBot.create(:resource_score_permission, :all_languages, user: user, country: "us")
      invite = FactoryBot.create(:user_invite, grants: {"us" => ["*"]})

      expect { invite.accept!(user) }.not_to change { user.resource_score_permissions.count }
      expect(invite.reload).to be_accepted
    end

    it "does not touch the acceptor's email, so an alias invite still applies" do
      invite = FactoryBot.create(:user_invite, email: "alias@partner.org")

      invite.accept!(user)

      expect(user.reload.email).not_to eq("alias@partner.org")
      expect(user.resource_score_grants).to eq({"us" => ["*"]})
    end

    it "promotes to admin when the invite carries the flag" do
      invite = FactoryBot.create(:user_invite, :superadmin)

      invite.accept!(user)

      expect(user.reload.admin).to be true
    end

    it "never demotes an existing admin" do
      admin = FactoryBot.create(:user, admin: true)
      invite = FactoryBot.create(:user_invite, admin: false)

      invite.accept!(admin)

      expect(admin.reload.admin).to be true
    end

    it "refuses a second use" do
      invite = FactoryBot.create(:user_invite)
      invite.accept!(user)
      other = FactoryBot.create(:user)

      expect { invite.accept!(other) }.to raise_error(UserInvite::AlreadyAccepted)
      expect(other.resource_score_permissions).to be_empty
    end

    it "refuses an expired invite" do
      invite = FactoryBot.create(:user_invite, :expired)

      expect { invite.accept!(user) }.to raise_error(UserInvite::Expired)
      expect(user.resource_score_permissions).to be_empty
      expect(invite.reload).not_to be_accepted
    end

    it "rolls back everything when a grant cannot be written" do
      invite = FactoryBot.create(:user_invite, :superadmin, grants: {"us" => ["*"]})
      allow_any_instance_of(ResourceScorePermission).to receive(:save!).and_raise("boom")

      expect { invite.accept!(user) }.to raise_error(RuntimeError, "boom")

      expect(user.reload.admin).to be false
      expect(user.resource_score_permissions).to be_empty
      expect(invite.reload).to be_pending
    end

    it "skips a language that disappeared after the invite was created" do
      invite = FactoryBot.create(:user_invite, grants: {"mx" => ["*"]})
      # Bypass validation to simulate a language deleted after the fact.
      invite.update_column(:grants, {"us" => ["zz"], "mx" => ["*"]})

      skipped = invite.accept!(user)

      expect(skipped).to eq(["us/zz"])
      expect(user.resource_score_grants).to eq({"mx" => ["*"]})
      expect(invite.reload).to be_accepted
    end
  end
end
