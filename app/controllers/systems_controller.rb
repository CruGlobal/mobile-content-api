class SystemsController < ApplicationController

  def getSystems
    systems = System.all
    render json: systems
  end

end