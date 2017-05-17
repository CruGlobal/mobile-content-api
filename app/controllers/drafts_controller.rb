# frozen_string_literal: true

class DraftsController < SecureController
  def index
    render json: Translation.where(is_published: false), include: params[:include], status: :ok
  end

  def show
    render plain: load_translation.build_translated_page(params[:page_id], false), status: :ok
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
    response.headers['Location'] = "drafts/#{d.id}"
    render json: d, status: :created
  end

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
  rescue Error::PhraseNotFoundError => e
    translation.errors.add(:id, e.message)
    render_error(translation, :conflict)
  end

  def load_translation
    Translation.find(params[:id])
  end
end
