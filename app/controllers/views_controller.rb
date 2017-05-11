# frozen_string_literal: true

class ViewsController < SecureController
  def create
    View.create!(params[:data][:attributes].permit(:quantity, :resource_id))
    head :no_content
  end
end
