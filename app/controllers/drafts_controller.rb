# frozen_string_literal: true

class DraftsController < SecureController
  def show
    render json: load_translation.build_translated_page(params[:page_id], false)
  end

  def create
    create_new_draft
  rescue Error::MultipleDraftsError
    d = Translation.new
    d.errors.add(:id, 'Draft already exists for this resource and language.')
    render_error(d, :bad_request)
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
    render_error(t, :bad_request)
  end

  private

  def create_new_draft
    resource = load_resource
    existing_translation = Translation.latest_translation(resource.id, language_id)

    d = existing_translation.nil? ? resource.create_new_draft(language_id) : existing_translation.create_new_version
    head :no_content, location: "drafts/#{d.id}"
  end

  def load_resource
    Resource.find(params[:data][:attributes][:resource_id])
  end

  def language_id
    params[:data][:attributes][:language_id]
  end

  def edit
    translation = load_translation
    translation.update_draft(params[:data][:attributes])
    head :no_content
  rescue Error::PhraseNotFoundError => e
    translation.errors.add(:id, e.message)
    render_error(translation, :conflict)
  end

  def load_translation
    Translation.find(params[:id])
  end
end
