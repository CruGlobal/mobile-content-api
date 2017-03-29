# frozen_string_literal: true

class DraftsController < ApplicationController
  def page
    download_page
  end

  def edit_page_structure
    head(edit_structure)
  end

  def publish_draft
    publish
  end

  def delete_draft
    delete
  end

  private

  def download_page
    translation = Translation.find(params[:draft_id])
    page_filename = Page.find(params[:page_id]).filename

    render json: translation.download_translated_page(page_filename)
  end

  def edit_structure
    translation = Translation.find(params[:id])
    translation.edit_page_structure(params[:page_id], params[:structure])
  end

  def publish
    translation = Translation.find(params[:id])
    translation.publish
  end

  def delete
    translation = Translation.find(params[:id])
    head translation.delete_draft!
  end
end
