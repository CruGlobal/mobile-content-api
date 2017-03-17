class ResourcesController < ApplicationController

  def getMeta
    resourceId = params[:id]
    resource = Resource.find(resourceId)
    render :json => resource, :include => :translations
  end

end