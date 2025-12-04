# frozen_string_literal: true

class ResourcesController < ApplicationController
  before_action :authorize!, only: %i[create update publish_translation]

  def index
    render json: cached_index_json, status: :ok
  end

  def show
    render json: load_resource, include: params[:include], fields: field_params, status: :ok
  end

  def create
    r = Resource.create!(permitted_params)
    render json: r, status: :created
  end

  def update
    resource = load_resource
    resource.set_data_attributes!(data_attrs) if resource.update!(permitted_params)

    render json: resource, status: :ok
  end

  def suggestions
    render json: ToolFilterService.new(params).call, include: params[:include], fields: field_params, status: :ok
  end

  def featured
    lang_code = params.dig(:filter, :lang) || params[:lang]
    featured_resources = all_featured_resources(
      lang_code: lang_code,
      country: params.dig(:filter, :country) || params[:country],
      resource_type: params.dig(:filter, :resource_type) || params[:resource_type]
    )

    render json: featured_resources, include: params[:include], status: :ok
  end

  def publish_translation
    if valid_publish_params?
      render json: publish_translations, status: :ok
    else
      render json: {errors: {"errors" => [{source: {pointer: "/data/attributes/id"}, detail: "Record not found."}]}},
        status: :unprocessable_content
    end
  end

  private

  def valid_publish_params?
    params.dig("data", "relationships", "languages", "data") && params["resource_id"]
  end

  def publish_translations
    draft_translations = []
    languages = params["data"]["relationships"]["languages"]["data"]

    languages.each do |lang|
      draft_translations << publish_translation_for_language(lang)
    end
    draft_translations
  end

  def publish_translation_for_language(language_data)
    draft_translation = find_or_create_draft_translation(language_data["id"])
    return unless draft_translation

    draft_translation.update(publishing_errors: nil)
    PublishTranslationJob.perform_async(draft_translation.id)
    draft_translation
  end

  def find_or_create_draft_translation(language_id)
    resource = Resource.find(params["resource_id"])

    draft = resource.create_draft(language_id) if resource
    draft
  end

  def cached_index_json
    cache_key = Resource.index_cache_key(all_resources,
      include_param: params[:include],
      fields_param: field_params)
    Rails.cache.fetch(cache_key, expires_in: 1.hour) { index_json }
  end

  def index_json
    ActiveModelSerializers::SerializableResource.new(
      all_resources.order(name: :asc),
      include: params[:include],
      fields: field_params
    ).to_json
  end

  def all_resources
    resources = if params.dig(:filter, :system)
      Resource.system_name(params[:filter][:system])
    else
      Resource.all
    end

    resources = resources.where(abbreviation: params[:filter][:abbreviation]) if params.dig(:filter, :abbreviation)

    if params.dig(:filter, :resource_type)
      resources = resources.joins(:resource_type).where(resource_types: {name: params[:filter][:resource_type].downcase})
    end

    resources
  end

  def all_featured_resources(lang_code:, country:, resource_type: nil)
    scope = Resource.includes(:resource_scores).left_joins(:resource_scores).where(resource_scores: {featured: true})

    if lang_code.present?
      language = Language.find_by(code: lang_code.downcase)
      scope = scope.joins(resource_scores: :language).where(languages: {id: language.id}) if language.present?
    end

    scope = scope.where("resource_scores.country = LOWER(:country)", country:) if country.present?
    if resource_type.present?
      scope = scope.joins(:resource_type).where(resource_types: {name: resource_type.downcase})
    end

    scope.order("resource_scores.featured_order ASC, resource_scores.featured DESC NULLS LAST, \
    resource_scores.score DESC NULLS LAST, \
    resources.created_at DESC")
  end

  def load_resource
    Resource.find(params[:id])
  end

  def permitted_params
    permit_params(:name, :abbreviation, :manifest, :crowdin_project_id, :system_id, :description, :resource_type_id,
      :metatool_id, :default_variant_id)
  end
end
