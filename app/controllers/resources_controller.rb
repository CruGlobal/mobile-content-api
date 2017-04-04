# frozen_string_literal: true

class ResourcesController < ApplicationController
  def show
    resource
  end

  private

  def resource
    render json: Resource.find(params[:id]), include: includes_param, status: :ok
  end

  def includes_param
    params[:include] || 'latest_translations'
  end
end
