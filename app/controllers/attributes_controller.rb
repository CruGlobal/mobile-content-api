# frozen_string_literal: true

class AttributesController < SecureController
  def create
    create_attribute
  end

  def update
    update_attr
  end

  def destroy
    destroy_attribute
  end

  private

  def create_attribute
    a = Attribute.create!(permitted_params)
    head :no_content, location: "attributes/#{a.id}"
  end

  def update_attr
    load_attribute.update!(permitted_params)
    head :no_content
  end

  def destroy_attribute
    load_attribute.destroy!
    head :no_content
  end

  def load_attribute
    Attribute.find(params[:id])
  end

  def permitted_params
    data_attrs.permit([:key, :value, :resource_id])
  end
end
