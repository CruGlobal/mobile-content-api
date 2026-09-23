# frozen_string_literal: true

# Redeems an invitation for the caller: POST /users/me/accept-invite.
#
# The token is the credential. There is deliberately no email match -- a
# superadmin may invite an alias that differs from the invitee's Okta login
# address -- so the only checks are that the token exists, is unexpired and has
# not been used.
#
# Not a WithUserController: that base class resolves a :user_id subject, and the
# controllers built on it let an admin act on anyone. Redemption has exactly one
# legal subject, the token bearer, so the route is a literal "me" and there is
# no id an admin could point somewhere else.
class UserInviteAcceptancesController < ApplicationController
  before_action :require_login!

  def create
    invite = UserInvite.find_by(token: token_param)

    return render_invite_error("invite_not_found", "That invitation link is not valid.", :not_found) if invite.nil?
    return render_invite_error("invite_already_accepted", "That invitation has already been used.", :conflict) if invite.accepted?
    return render_invite_error("invite_expired", "That invitation expired on #{invite.expires_at.to_date}.", :gone) if invite.expired?

    skipped = invite.accept!(current_user)

    # The user, not the invite: the admin app calls this right before it reads
    # the profile, so answering with the fresh admin flag and grants saves it a
    # round trip and guarantees the two agree.
    render json: current_user,
      meta: {"accepted-invite-id" => invite.id.to_s, "skipped-grants" => skipped},
      status: :ok
  rescue UserInvite::AlreadyAccepted
    render_invite_error("invite_already_accepted", "That invitation has already been used.", :conflict)
  rescue UserInvite::Expired
    render_invite_error("invite_expired", "That invitation has expired.", :gone)
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  end

  private

  def token_param
    token = data_attrs.permit(:token)[:token].to_s.strip
    raise InvalidRequestError, "token is required" if token.blank?

    token
  end

  def render_invite_error(code, detail, status)
    render json: {errors: [{code: code, detail: detail}]}, status: status
  end
end
