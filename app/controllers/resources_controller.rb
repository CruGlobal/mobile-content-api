class ResourcesController < ApplicationController

  def getMeta
    resourceId = params[:id]
    resource = Resource.find(resourceId)
    render :json => resource, :include => :translations
  end

  def downloadResource
    systemId = params[:systemId]
    resourceId = params[:resourceId]
    languageCode = params[:languageId]

    path = 'https://s3.amazonaws.com/' + ENV['GODTOOLS_V2_BUCKET'] + '/' + systemId + '/' + resourceId + '/' + languageCode + '.zip'

    redirect_to path, :status => 302

  end

end