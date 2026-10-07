# frozen_string_literal: true

# Management of which (country, language) pairs a user may edit ResourceScores
# for. Handing out edit access is itself a superuser action, so every writing
# action stays behind require_admin!.
#
# Reading is the exception: an editor may read their own grants, so the admin UI
# can grey out the locales they cannot touch without having to be an admin to
# ask. Reading someone else's still requires admin.
#
# WithUserController owns the shared shape of /users/:user_id/... -- the token
# check, the "me" subject convention, and the self-only 403 -- and this widens
# only the last of those, so the 401/403 split stays the same everywhere: no
# token is unauthenticated, a valid token without the rights is forbidden.
class ResourceScorePermissionsController < WithUserController
  before_action :require_admin!, except: :index
  before_action :require_subject!

  def index
    render json: @user.resource_score_permissions.includes(:language),
      include: params[:include],
      meta: {grants: @user.resource_score_grants},
      status: :ok
  end

  def create
    permission = @user.resource_score_permissions.new(
      country: ResourceScoreGrants.normalized_country(create_params[:country]),
      language: ResourceScoreGrants.resolve_language(create_params[:lang])
    )
    permission.save!

    render json: permission, status: :created
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  def destroy
    permission = @user.resource_score_permissions.find(params[:id])
    permission.destroy!

    render json: {}, status: :ok
  end

  # Replaces the user's entire grant map in one call, which is how the admin UI
  # edits it: {"mx": ["es"], "us": ["en", "es"], "vn": ["*"]}
  #
  # Resolution (country/language checks, duplicate detection) lives in
  # ResourceScoreGrants, shared with the invite flow. This stays the destructive
  # replace; only UserInvite#accept! merges additively.
  def mass_update
    resolved = ResourceScoreGrants.resolve(incoming_grants)

    ResourceScorePermission.transaction do
      @user.resource_score_permissions.destroy_all
      resolved.each do |country, language|
        @user.resource_score_permissions.create!(country: country, language: language)
      end
    end

    @user.resource_score_permissions.reload
    render json: @user.resource_score_permissions.includes(:language),
      include: params[:include],
      meta: {grants: @user.resource_score_grants},
      status: :ok
  rescue InvalidRequestError => e
    render json: {errors: [{detail: "Error: #{e.message}"}]}, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: formatted_errors("record_invalid", e)}, status: :unprocessable_content
  end

  protected

  # Admins manage anyone's grants; everyone else is held to the inherited
  # self-only rule, which refuses an unknown id and someone else's id alike.
  def authorized_for_subject?
    current_user&.admin || super
  end

  private

  # Only an admin gets past authorize_user! with a missing subject, and they are
  # entitled to know which users exist, so a 404 here leaks nothing.
  def require_subject!
    raise ActiveRecord::RecordNotFound, "Couldn't find User with 'id'=#{params[:user_id]}" if @user.nil?
  end

  def create_params
    params.require(:data).require(:attributes).permit(:country, :lang)
  end

  def incoming_grants
    grants = params.require(:data).require(:attributes)[:grants]
    raise InvalidRequestError, "grants must be an object keyed by country code" unless grants.respond_to?(:to_unsafe_h)

    grants.to_unsafe_h
  end
end
