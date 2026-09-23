# frozen_string_literal: true

# Superadmin management of dashboard invitations: create, list, edit, revoke and
# resend. Every action is admin-only via SecureController; the invite's token is
# a bearer credential and this is the only place it is ever serialized.
#
# Redemption is a different concern with a different caller (the invitee, who
# is usually not an admin) and lives in UserInviteAcceptancesController.
class UserInvitesController < SecureController
  def index
    invites = scoped_invites.includes(:invited_by, :accepted_by).order(created_at: :desc)

    render json: invites, meta: {total: invites.size}, status: :ok
  end

  def show
    render json: invite, status: :ok
  end

  def create
    existing = UserInvite.pending.find_by(email: invite_params[:email])
    if existing
      render json: {
        errors: [{
          code: "invite_already_pending",
          detail: "A pending invitation for #{existing.email} already exists; resend or revoke it instead.",
          meta: {"invite-id" => existing.id.to_s}
        }]
      }, status: :conflict
      return
    end

    new_invite = UserInvite.new(invite_params.merge(invited_by: current_user))
    new_invite.save!
    UserInviteNotifier.deliver(new_invite)

    render json: new_invite, meta: delivery_meta(new_invite), status: :created
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  # Editing a pending invite changes what the already-distributed link will
  # grant; the token itself is untouched, so nothing has to be re-sent.
  def update
    invite.update!(invite_params)

    render json: invite, status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  def destroy
    invite.destroy!

    render json: {}, status: :ok
  end

  def resend
    invite.resend!
    UserInviteNotifier.deliver(invite)

    render json: invite, meta: delivery_meta(invite), status: :ok
  end

  private

  def invite
    @invite ||= UserInvite.find(params[:id])
  end

  # Pending is the working set; the rest is opt-in so the audit trail stays
  # reachable without cluttering the dashboard's default listing.
  def scoped_invites
    case status_filter
    when "expired" then UserInvite.expired
    when "accepted" then UserInvite.accepted
    when "all" then UserInvite.all
    else UserInvite.pending
    end
  end

  # ?filter=pending is not the nested JSON:API shape; read a scalar as absent
  # rather than indexing into a String.
  def status_filter
    filter = params[:filter]
    filter.is_a?(ActionController::Parameters) ? filter[:status].presence : nil
  end

  # JSON:API names mapped onto real columns. compact so an absent key leaves the
  # column alone on update; false is kept, only nil dropped. grants is
  # normalized here so a bad country or language answers at invite time, not
  # when someone tries to redeem it.
  def invite_params
    permitted = data_attrs.permit(:email, :"given-name", :"family-name", :admin, :"email-is-alias", grants: {})

    {
      email: permitted[:email]&.strip,
      first_name: permitted[:"given-name"],
      last_name: permitted[:"family-name"],
      admin: permitted[:admin],
      email_is_alias: permitted[:"email-is-alias"],
      grants: permitted[:grants] && ResourceScoreGrants.normalize_map(permitted[:grants])
    }.compact
  end

  # Whether the API sent the email itself. False until a mailer exists, so the
  # dashboard knows to hand the link over instead.
  def delivery_meta(invite)
    {"delivered" => UserInviteNotifier.enabled?, "invite-url" => invite.url}
  end
end
