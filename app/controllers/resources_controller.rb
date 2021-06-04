# frozen_string_literal: true

require "page_client"

class ResourcesController < ApplicationController
  before_action :authorize!, only: [:create, :update, :push_to_onesky]

  def index
    render json: all_resources.order(name: :asc), include: params[:include], fields: field_params, status: :ok
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

  private

  def all_resources
    if params["filter"]
      Resource.system_name(params["filter"]["system"])
    else
      Resource.all
    end
  end

  def load_resource
    Resource.find(params[:id])
  end

  def permitted_params
    permit_params(:name, :abbreviation, :manifest, :onesky_project_id, :system_id, :description, :resource_type_id)
  end
end
