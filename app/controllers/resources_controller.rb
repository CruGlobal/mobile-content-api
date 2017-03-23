# frozen_string_literal: true

class ResourcesController < ApplicationController
  def meta
    resource_id = params[:id]
    resource = Resource.find(resource_id)
    render json: resource, include: :translations
  end

  def download_resource
    system = System.where(id: params[:system_id]).first
    resource = Resource.where(id: params[:resource_id]).first
    language_code = params[:language_id]

    path = 'https://s3.amazonaws.com/' + ENV['GODTOOLS_V2_BUCKET'] + '/' + system.name + '/' + resource.abbreviation + '/' + language_code + '.zip'

    redirect_to path, status: 302
  end
end
