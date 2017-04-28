# frozen_string_literal: true

class DraftsController < SecureController
  def show
    render json: load_translation.build_translated_page(params[:page_id], false)
  end

  def create
    create_new_draft
  end

  def update
    edit
  end

  def destroy
    load_translation.destroy!
    head :no_content
  rescue Error::TranslationError => e
    t = Translation.new
    t.errors.add(:id, e.message)
    render json: t, status: :bad_request, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
  end

  private

  def create_new_draft
    resource = load_resource
    existing_translation = Translation.latest_translation(resource.id, language_id)

    if existing_translation.nil?
      resource.create_new_draft(language_id)
    elsif !existing_translation.is_published
      existing_translation.errors.add(:id, 'Draft already exists for this resource and language.')
      render json: existing_translation,
             status: :bad_request,
             adapter: :json_api,
             serializer: ActiveModel::Serializer::ErrorSerializer
    else
      existing_translation.create_new_version
    end
  end

  def load_resource
    Resource.find(params[:data][:attributes][:resource_id])
  end

  def language_id
    params[:data][:attributes][:language_id]
  end

  def edit
    load_translation.update_draft(params)
  end

  def load_translation
    Translation.find(params[:id])
  end
end
