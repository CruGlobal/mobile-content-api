# frozen_string_literal: true

class CustomPagesController < ApplicationController
  def create
    head(upsert_custom_page)
  end

  def upsert_custom_page
    translation = Translation.find(params[:id])
    translation.edit_page_structure(params[:page_id], params[:structure])
  end
end
