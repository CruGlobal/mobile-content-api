# frozen_string_literal: true

# An invitation to the admin dashboard. See the migration for why this is its
# own table rather than a state on users.
#
# Lifecycle: pending -> accepted (or expired). Accepting merges the invite's
# grants into the redeeming user additively -- nothing is revoked and an
# existing admin is never demoted -- then stamps accepted_at/accepted_by, which
# is what makes the token single-use. Accepted rows stay as the audit trail.
class UserInvite < ApplicationRecord
  DEFAULT_TTL = 7.days
  TOKEN_LENGTH = 32

  class Expired < StandardError; end

  class AlreadyAccepted < StandardError; end

  has_secure_token :token, length: TOKEN_LENGTH

  belongs_to :invited_by, class_name: "User", optional: true
  belongs_to :accepted_by, class_name: "User", optional: true

  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :expires_at, presence: true
  # Only when the map is being written: accept! stamps accepted_at on a row
  # whose map may reference a language deleted since, and that must not block.
  validate :grants_are_resolvable, if: -> { new_record? || will_save_change_to_grants? }
  validate :only_one_pending_per_email, on: :create

  before_validation :default_expiry, on: :create

  scope :pending, -> { where(accepted_at: nil).where(arel_table[:expires_at].gt(Time.current)) }
  scope :expired, -> { where(accepted_at: nil).where(arel_table[:expires_at].lteq(Time.current)) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def accepted?
    accepted_at.present?
  end

  def expired?
    !accepted? && expires_at.present? && !expires_at.future?
  end

  def pending?
    !accepted? && !expired?
  end

  def status
    if accepted?
      "accepted"
    elsif expired?
      "expired"
    else
      "pending"
    end
  end

  # The link the invitee opens. The admin app owns the /invite route; it stashes
  # the code, sends the person through Okta, and redeems the code afterwards.
  def url
    "#{Rails.configuration.x.admin_app_base_url}/invite?code=#{token}"
  end

  # Rotates the credential and restarts the clock, so the old link stops working.
  def resend!
    update!(
      token: self.class.generate_unique_secure_token(length: TOKEN_LENGTH),
      expires_at: DEFAULT_TTL.from_now
    )
    self
  end

  # Merges the invite into `user`. Runs under a row lock and re-checks the state
  # inside it, so two simultaneous redemptions cannot both apply.
  #
  # @return [Array<String>] "country/code" grants that could not be resolved
  #   and were skipped (a language deleted since the invite was created)
  # @raise [AlreadyAccepted, Expired]
  def accept!(user)
    skipped = []

    with_lock do
      raise AlreadyAccepted if accepted?
      raise Expired if expired?

      pairs, skipped = ResourceScoreGrants.resolve_lenient(grants)

      user.update!(admin: true) if admin? && !user.admin?

      pairs.each do |country, language|
        # first_or_create! rather than create!: the user may be an existing
        # one who already holds the grant, and re-granting must be a no-op.
        user.resource_score_permissions
          .where(country: country, language_id: language&.id)
          .first_or_create!
      end

      update!(accepted_at: Time.current, accepted_by: user)
    end

    # The association may have been loaded before the merge; drop the stale copy
    # so the serialized user shows the grants just added.
    user.resource_score_permissions.reset
    skipped
  end

  private

  def default_expiry
    self.expires_at ||= DEFAULT_TTL.from_now
  end

  def grants_are_resolvable
    unless grants.is_a?(Hash)
      errors.add(:grants, "must be an object keyed by country code")
      return
    end

    ResourceScoreGrants.resolve(grants)
  rescue InvalidRequestError => e
    errors.add(:grants, e.message)
  end

  # The controller checks this first to answer with a 409 that points at the
  # existing invite; this is the fallback that keeps a race from creating two.
  def only_one_pending_per_email
    return if email.blank?
    return unless UserInvite.pending.where(email: email).exists?

    errors.add(:email, "already has a pending invitation")
  end
end
