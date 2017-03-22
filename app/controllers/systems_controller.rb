# frozen_string_literal: true

class SystemsController < ApplicationController
  def systems
    systems = System.all
    render json: systems
  end

  def resources
    system_id = params[:id]
    system = System.find(system_id)
    render json: system.resources
  end
end
