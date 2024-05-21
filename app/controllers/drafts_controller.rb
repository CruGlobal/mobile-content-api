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

  def load_translation
    Translation.find(params[:id])
  end
end
