# frozen_string_literal: true

class DraftsController < SecureController
  def index
    render json: Translation.where(is_published: false), include: params[:include], status: :ok
  end

  def show
    if params[:page_id]
      resource = load_translation.translated_page(params[:page_id], false)
    elsif params[:tip_id]
      resource = load_translation.translated_tip(params[:tip_id], false)
    end
    render plain: resource, status: :ok
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

    # Note that this endpoint isn't used for anything other than publishing to s3. Eventually once the new client switches
    # to the new way of publishing, we'll delete this file
    # see: https://jira.cru.org/browse/GT-2182
    do_publishing = data_attrs[:is_published]

    translation.push_published_to_s3 if do_publishing
    render json: translation, status: :ok
  end

  def load_translation
    Translation.find(params[:id])
  end
end
