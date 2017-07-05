class LanguageIdNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column_null :custom_pages, :language_id, false
  end
end
