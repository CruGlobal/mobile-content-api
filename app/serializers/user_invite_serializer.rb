# frozen_string_literal: true

# token and invite-url are bearer credentials: whoever holds them gets the
# grants. They are serialized here only because every action that renders an
# invite sits behind require_admin!, and the dashboard needs the URL per row for
# "Copy invite link". Never render this serializer on an unauthenticated route.
class UserInviteSerializer < ActiveModel::Serializer
  type "user-invite"

  attributes :email, :admin, :grants, :status, :token
  attribute :first_name, key: "given-name"
  attribute :last_name, key: "family-name"
  attribute :email_is_alias, key: "email-is-alias"
  attribute :expires_at, key: "expires-at"
  attribute :created_at, key: "created-at"
  attribute :accepted_at, key: "accepted-at"
  attribute :url, key: "invite-url"
  attribute :invited_by_id, key: "invited-by-id"
  attribute :accepted_by_id, key: "accepted-by-id"

  # iso8601 rather than the default, which adds millisecond digits.
  def expires_at
    object.expires_at.iso8601
  end

  def created_at
    object.created_at.iso8601
  end

  def accepted_at
    object.accepted_at&.iso8601
  end

  def invited_by_id
    object.invited_by_id&.to_s
  end

  def accepted_by_id
    object.accepted_by_id&.to_s
  end
end
