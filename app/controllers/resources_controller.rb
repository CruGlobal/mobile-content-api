# frozen_string_literal: true

require "page_client"

class ResourcesController < ApplicationController
  before_action :authorize!, only: [:create, :update, :push_to_onesky]

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
    if resource.update!(permitted_params)
      resource.set_data_attributes!(data_attrs)
    end

    render json: resource, status: :ok
  end

  def push_to_onesky
    # TODO: this could be done for individual pages when their structure is updated
    PageClient.new(load_resource, "en").push_new_onesky_translation param?("keep-existing-phrases")

    head :no_content
  end

  def suggestions
    render json: ToolFilterService.new(params).call, include: params[:include], fields: field_params, status: :ok
  end

  def publish_translation
    if valid_publish_params?
      render json: publish_translations, status: :ok
    else
      render json: {errors: {"errors" => [{source: {pointer: "/data/attributes/id"}, detail: "Record not found."}]}}, status: :unprocessable_entity
    end
  end

  private

  def valid_publish_params?
    params.dig("data", "relationships", "languages", "data") && params["resource_id"]
  end

  def publish_translations
    translations = []
    languages = params["data"]["relationships"]["languages"]["data"]

    languages.each do |lang|
      translations << publish_translation_for_language(lang)
    end
    translations
  end

  def publish_translation_for_language(language_data)
    translation = find_or_create_latest_translation(language_data["id"])
    if translation
      PublishTranslationJob.perform_async(translation.id)
      translation
    end
  end

  def find_or_create_latest_translation(language_id)
    Translation.find_or_create_by!(resource_id: params["resource_id"], language_id: language_id, is_published: false)
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

    if params.dig(:filter, :abbreviation)
      resources = resources.where(abbreviation: params[:filter][:abbreviation])
    end

    resources
  end

  def load_resource
    Resource.find(params[:id])
  end

  def permitted_params
    permit_params(:name, :abbreviation, :manifest, :onesky_project_id, :system_id, :description, :resource_type_id, :metatool_id, :default_variant_id)
  end
end
