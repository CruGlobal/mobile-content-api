# frozen_string_literal: true

class SystemsController < ApplicationController
  def systems
    all_systems
  end

  def resources
    system
  end

  private

  def all_systems
    render json: System.all, status: :ok
  end

  def system
    render json: System.find(params[:id]), status: :ok
  end
end
