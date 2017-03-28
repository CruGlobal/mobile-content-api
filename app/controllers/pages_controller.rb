# frozen_string_literal: true

class PagesController < ApplicationController
  def edit
    page = Page.find(params[:id])
    page.update(structure: params[:structure])
  end
end
