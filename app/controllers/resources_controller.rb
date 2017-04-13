# frozen_string_literal: true

class ResourcesController < ApplicationController
  def index
    render json: all_resources, status: :ok
  end

  def show
    resource
  end

  private

  def all_resources
    if params[:system]
      Resource.system_name(params[:system])
    else
      Resource.all
    end
  end

  def resource
    render json: Resource.find(params[:id]), include: includes_param, status: :ok
  end

  def includes_param
    params[:include] || 'latest_translations'
  end
end
