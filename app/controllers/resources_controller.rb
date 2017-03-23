# frozen_string_literal: true

class ResourcesController < ApplicationController
  def meta
    resource_id = params[:id]
    resource = Resource.find(resource_id)
    render json: resource, include: :translations
  end
end
