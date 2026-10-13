# frozen_string_literal: true

# Where the invitation email will be sent from, once there is a way to send one.
#
# This app has no working mail path (ApplicationMailer is a stub and production
# mail is disabled), so for now the superadmin hands the link over themselves.
# The seam exists so wiring a mailer later is a change inside `deliver`, not to
# the endpoint contract: callers already ask whether delivery happened and the
# response already says so in meta.delivered.
class UserInviteNotifier
  def self.enabled?
    false
  end

  # @return [Boolean] whether an email was queued
  def self.deliver(invite)
    return false unless enabled?

    # InviteMailer.with(invite: invite).invitation.deliver_later
    true
  end
end
