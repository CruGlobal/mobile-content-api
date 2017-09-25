# frozen_string_literal: true

class DraftsController < SecureController
  def index
    render json: Translation.where(is_published: false), include: params[:include], status: :ok
  end

  def show
    render plain: load_translation.translated_page(params[:page_id], false), status: :ok
  end

  def create
    resource = load_resource

    resource.create_draft(language_id) unless language_id.nil?

    data_attrs[:language_ids]&.each do |language_id|
      resource.create_draft(language_id)
    end

    head :no_content
  end

  def update
    edit
  end

  def destroy
    load_translation.destroy!
    head :no_content
  end

  private

  def load_resource
    Resource.find(data_attrs[:resource_id])
  end

  def language_id
    data_attrs[:language_id]
  end

  def edit
    translation = load_translation
    translation.update_draft(data_attrs)
    render json: translation, status: :ok
  end

  def load_translation
    Translation.find(params[:id])
  end
end
