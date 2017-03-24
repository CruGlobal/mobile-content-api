# frozen_string_literal: true

class ResourcesController < ApplicationController
  def meta
    resource = Resource.find(params[:id])
    render json: resource, include: :translations
  end
end
