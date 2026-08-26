# frozen_string_literal: true

# Management of which (country, language) pairs a user may edit ResourceScores
# for. Handing out edit access is itself a superuser action, so every writing
# action stays behind require_admin!.
#
# Reading is the exception: an editor may read their own grants, so the admin UI
# can grey out the locales they cannot touch without having to be an admin to
# ask. Reading someone else's still requires admin.
class ResourceScorePermissionsController < ApplicationController
  before_action :require_login!, only: :index
  before_action :require_admin!, except: :index
  before_action :load_user
  before_action :require_self_or_admin!, only: :index

  def index
    render json: @user.resource_score_permissions.includes(:language),
      include: params[:include],
      meta: {grants: @user.resource_score_grants},
      status: :ok
  end

  def create
    country = normalized_country(create_params[:country])
    permission = @user.resource_score_permissions.new(
      country: country,
      language: resolve_language(create_params[:lang])
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
  def mass_update
    grants = incoming_grants
    resolved = grants.flat_map do |country, langs|
      normalized = normalized_country(country)
      Array(langs).map { |lang| [normalized, resolve_language(lang)] }
    end

    duplicates = resolved.tally.select { |_pair, count| count > 1 }.keys
    if duplicates.any?
      raise InvalidRequestError,
        "duplicate grants: #{duplicates.map { |country, language| "#{country}/#{language&.code || ResourceScorePermission::ALL_LANGUAGES}" }.join(", ")}"
    end

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

  private

  # "me" mirrors the subject convention WithUserController already uses for the
  # other per-user endpoints.
  def load_user
    @user = (params[:user_id] == "me") ? current_user : User.find(params[:user_id])
  end

  def require_self_or_admin!
    return if current_user&.admin
    return if @user == current_user

    render_forbidden
  end

  def create_params
    params.require(:data).require(:attributes).permit(:country, :lang)
  end

  def incoming_grants
    grants = params.require(:data).require(:attributes)[:grants]
    raise InvalidRequestError, "grants must be an object keyed by country code" unless grants.respond_to?(:to_unsafe_h)

    grants.to_unsafe_h
  end

  def normalized_country(country)
    normalized = country.to_s.downcase
    unless CountryCodes.valid?(normalized)
      raise InvalidRequestError, "'#{country}' is not a recognized ISO 3166-1 alpha-2 country code"
    end

    normalized
  end

  # nil (or "*") means every language in that country.
  def resolve_language(code)
    return nil if code.blank? || code == ResourceScorePermission::ALL_LANGUAGES

    language = Language.find_by_code(code)
    raise InvalidRequestError, "Language not found for code: #{code}" unless language

    language
  end
end
