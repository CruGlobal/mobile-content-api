# frozen_string_literal: true

class PagesController < SecureController
  def edit
    page = Page.find(params[:id])
    page.update(structure: params[:structure])
  end
end
