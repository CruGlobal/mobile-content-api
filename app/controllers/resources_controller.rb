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
    if params['filter']
      Resource.system_name(params['filter']['system'])
    else
      Resource.all
    end
  end

  def resource
    render json: Resource.find(params[:id]), include: params[:include], status: :ok
  end
end
