# frozen_string_literal: true

class StatsController < SecureController
  def create
    Stat.create!(params[:data][:attributes].permit(:quantity, :resource_id))
    head :created
  end
end
