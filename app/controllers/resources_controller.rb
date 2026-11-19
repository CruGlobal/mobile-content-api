# frozen_string_literal: true

class ResourcesController < ApplicationController
  TOTAL_VIEWS_KEY = "total-views"
  TOTAL_VIEWS_PLACEHOLDER_PREFIX = "__total_views_for_resource_"
  TOTAL_VIEWS_PLACEHOLDER = /"#{TOTAL_VIEWS_KEY}":"#{TOTAL_VIEWS_PLACEHOLDER_PREFIX}(\d+)"/

  before_action :require_admin!, only: %i[create update publish_translation]

  def index
    render json: index_response_json, status: :ok
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

  # The index is expensive to build, so its JSON is cached. A new view does not
  # change the cache key: views arrive very often, and a rebuild after each one
  # would make the cache useless. Instead the cached JSON keeps a placeholder for
  # each resource's total-views value, and each response writes the current
  # values into those placeholders. No full parse of the cached JSON is needed.
  def index_response_json
    fresh_json = nil
    cached = Rails.cache.fetch(index_cache_key, expires_in: 1.hour) do
      fresh_json = index_json
      index_cache_entry(fresh_json)
    end
    # On a cache miss the JSON was just built, so its values are already current.
    return fresh_json if fresh_json
    return cached[:body] if cached[:views].empty?

    current = Resource.where(id: cached[:views].keys).pluck(:id, :total_views).to_h
    fill_total_views(cached[:body], cached[:views].merge(current))
  end

  def index_cache_key
    "#{Resource.index_cache_key(all_resources, include_param: params[:include], fields_param: field_params)}/total-views-placeholders"
  end

  # Builds {body:, views:}. body is the index JSON with a placeholder in place of
  # each total-views value, and views maps resource id to the total_views value
  # read at build time.
  def index_cache_entry(json)
    document = JSON.parse(json)
    views = {}
    (Array.wrap(document["data"]) + Array.wrap(document["included"])).each do |item|
      attributes = item["attributes"]
      next unless item["type"] == "resource" && attributes&.key?(TOTAL_VIEWS_KEY)

      id = Integer(item["id"])
      views[id] = attributes[TOTAL_VIEWS_KEY]
      attributes[TOTAL_VIEWS_KEY] = "#{TOTAL_VIEWS_PLACEHOLDER_PREFIX}#{id}"
    end
    # ActiveSupport encoding keeps the same escaping as the uncached response.
    {body: ActiveSupport::JSON.encode(document), views: views}
  end

  # Inside a JSON string every quote is escaped, so this pattern can only match
  # a real "total-views" key and its placeholder value, never text in a manifest.
  def fill_total_views(body, views)
    body.gsub(TOTAL_VIEWS_PLACEHOLDER) { %("#{TOTAL_VIEWS_KEY}":#{JSON.generate(views[$1.to_i])}) }
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
      resources = resources.joins(:resource_type).where(resource_types: {name: ResourceType.expand_name(params[:filter][:resource_type])})
    end

    resources
  end

  def load_resource
    Resource.find(params[:id])
  end

  def permitted_params
    permit_params(:name, :abbreviation, :manifest, :crowdin_project_id, :system_id, :description, :resource_type_id,
      :metatool_id, :default_variant_id)
  end
end
