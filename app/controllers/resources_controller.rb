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
    render json: ToolFilterService.new(params).call, status: :ok
  end

  private

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
