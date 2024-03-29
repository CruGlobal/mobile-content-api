# frozen_string_literal: true

class TranslatedAttributesController < SecureController
  before_action :load_resource

  def create
    create_translated_attr
  end

  def update
    update_translated_attr
  end

  def destroy
    destroy_translated_attr
  end

  private

  def create_translated_attr
    a = @resource.translated_attributes.create(permitted_params)

    render_translation_attribute_error(a) and return if a.errors.any?

    render json: a, status: :created, location: "/resources/#{@resource.id}/translated-attributes/#{a.id}"
  end

  def update_translated_attr
    a = load_translated_attr
    a.update(permitted_params)

    render_translation_attribute_error(a) and return if a.errors.any?

    render json: a, status: :ok
  end

  def render_translation_attribute_error(a)
    if a.errors[:key] == ["has already been taken"]
      render(json: {errors: {"code" => "key_already_exists"}}, status: 400)
    elsif a.errors[:key] == ["can't be blank"]
      render(json: {errors: {"code" => "invalid_key"}}, status: 400)
    elsif a.errors[:onesky_phrase_id] == ["can't be blank"]
      render(json: {errors: {"code" => "invalid_onesky_phrase_id"}}, status: 400)
    elsif a.errors.any?
      raise("error creating translated attr")
    end
  end

  def destroy_translated_attr
    load_translated_attr.destroy!
    head :no_content
  end

  def load_translated_attr
    @resource.translated_attributes.find(params[:id])
  end

  def permitted_params
    data_attrs[:onesky_phrase_id] = data_attrs.delete(:"onesky-phrase-id") if data_attrs[:"onesky-phrase-id"]
    permit_params(:key, :onesky_phrase_id, :required)
  end

  def load_resource
    @resource = Resource.find(params[:resource_id])
  end
end
