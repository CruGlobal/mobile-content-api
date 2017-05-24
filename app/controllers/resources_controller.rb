# frozen_string_literal: true

require 'page_util'

class ResourcesController < ApplicationController
  before_action :authorize!, only: [:update, :push_to_onesky]

  def index
    render json: all_resources, include: params[:include], status: :ok
  end

  def show
    render json: load_resource, include: params[:include], status: :ok
  end

  def update
    r = load_resource.update!(data_attrs.permit(permitted_params))
    render json: r, status: :ok
  end

  def push_to_onesky # TODO: this should be part of update via a callback
    PageUtil.new(load_resource, 'en').push_new_onesky_translation(params['keep-existing-phrases'])

    head :no_content
  end

  private

  def all_resources
    if params['filter']
      Resource.system_name(params['filter']['system'])
    else
      Resource.all
    end
  end

  def load_resource
    Resource.find(params[:id])
  end

  def permitted_params
    [:name, :abbreviation, :manifest, :onesky_project_id, :system_id, :description]
  end
end
