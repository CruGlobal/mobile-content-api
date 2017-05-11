# frozen_string_literal: true

class PagesController < SecureController
  def update
    page = Page.find(params[:id])
    page.update(structure: params[:data][:attributes][:structure])
    render json: page, status: :ok
  end
end
