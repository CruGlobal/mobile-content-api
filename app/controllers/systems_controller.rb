class SystemsController < ApplicationController

  def getSystems
    systems = System.all
    render json: systems
  end

  def getResources
    systemId = params[:id]
    system = System.find(systemId)
    render json: system.resources
  end

end