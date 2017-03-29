# frozen_string_literal: true

class ResourcesController < ApplicationController
  def meta
    resource
  end

  def create_draft
    create_new_draft
  end

  private

  def resource
    render json: Resource.find(params[:id]), include: :translations, status: :ok
  end

  def create_new_draft
    resource = Resource.find(params[:id])
    language_id = params[:language_id]
    existing_translation = Translation.latest_translation(resource.id, language_id)

    if existing_translation.nil?
      resource.create_new_draft(language_id)
    elsif !existing_translation.is_published
      render json: 'Draft already exists for this resource and language.', status: 400
    else
      existing_translation.add_new_version
    end
  end
end
