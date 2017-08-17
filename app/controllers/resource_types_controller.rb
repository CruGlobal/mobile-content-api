# frozen_string_literal: true

class ResourceTypesController < ApplicationController
  def index
    render json: ResourceType.all, status: :ok
  end
end
