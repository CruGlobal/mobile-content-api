# frozen_string_literal: true

class TranslatedAttributesController < SecureController
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
    TranslatedAttribute.create_attribute(params[:translated_attribute].permit(permitted_params))
  end

  def update_translated_attr
    load_translated_attr.update(params.permit(permitted_params))
  end

  def destroy_translated_attr
    load_translated_attr.destroy
  end

  def load_translated_attr
    TranslatedAttribute.find(params[:id])
  end

  def permitted_params
    [:value, :attribute_id, :translation_id]
  end
end
