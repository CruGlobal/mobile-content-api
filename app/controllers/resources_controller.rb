# frozen_string_literal: true

class ResourcesController < ApplicationController
  def meta
    resource
  end

  private

  def resource
    render json: Resource.find(params[:id]), include: :translations, status: :ok
  end
end
