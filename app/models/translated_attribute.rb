# frozen_string_literal: true

class TranslatedAttribute < ActiveRecord::Base
  belongs_to :parent_attribute, foreign_key: :attribute_id, class_name: 'Attribute'
  belongs_to :translation

  before_validation :parent_must_be_translatable

  private

  def parent_must_be_translatable
    raise 'Parent attribute is not translatable.' unless parent_attribute.is_translatable
  end
end
