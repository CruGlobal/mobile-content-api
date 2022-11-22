class TranslationAttributesChangeAttributeIdForKey < ActiveRecord::Migration[6.1]
  def change
    remove_column :translation_attributes, :attribute_id
    add_column :translation_attributes, :key, :string
  end
end
