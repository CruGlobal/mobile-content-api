# frozen_string_literal: true

class DraftsController < ApplicationController
  def show
    download_page
  end

  def create
    create_new_draft
  end

  def update
    publish
  end

  def destroy
    delete
  end

  private

  def download_page
    translation = Translation.find(params[:id])
    page_filename = Page.find(params[:page_id]).filename

    render json: translation.download_translated_page(page_filename)
  end

  def create_new_draft
    resource = Resource.find(params[:resource_id])
    language_id = params[:language_id]
    existing_translation = Translation.latest_translation(resource.id, language_id)

    if existing_translation.nil?
      resource.create_new_draft(language_id)
    elsif !existing_translation.is_published
      render json: 'Draft already exists for this resource and language.', status: 400
    else
      existing_translation.create_new_version
    end
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
