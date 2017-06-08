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
    existing_translation = Translation.latest_translation(resource.id, language_id)

    d = existing_translation.nil? ? resource.create_new_draft(language_id) : existing_translation.create_new_version
    response.headers['Location'] = "drafts/#{d.id}"
    render json: d, status: :created
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
