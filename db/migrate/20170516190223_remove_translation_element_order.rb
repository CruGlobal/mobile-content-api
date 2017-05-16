class RemoveTranslationElementOrder < ActiveRecord::Migration[5.0]
  def change
    remove_column :translation_elements, :page_order, :string
  end
end
