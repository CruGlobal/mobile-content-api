# frozen_string_literal: true

class TranslatedAttribute < ActiveRecord::Base
  belongs_to :parent_attribute, foreign_key: :attribute_id, class_name: "Attribute", inverse_of: :translated_attributes
  belongs_to :translation

  validates :value, presence: true
  validates :parent_attribute, presence: true
  validates :translation, presence: true, uniqueness: {scope: :parent_attribute}
  validate do
    errors.add("parent-attribute", "Is not translatable.") unless parent_attribute.is_translatable
  end
end
