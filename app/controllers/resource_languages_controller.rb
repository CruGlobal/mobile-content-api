class ResourceLanguagesController < ApplicationController
  def show
    resource = Resource.find(params[:resource_id])
    language = Language.find(params[:id])
    @resource_language = ResourceLanguage.new(resource: resource, language: language)
    render json: @resource_language, include: params[:include], status: :ok
  end

  def update
  end
end
