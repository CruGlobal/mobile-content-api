# frozen_string_literal: true

class ResourcesController < ApplicationController
  def show
    resource
  end

  private

  def resource
    render json: Resource.find(params[:id]), status: :ok
  end
end
