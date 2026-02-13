class ConvertResourceScoreLangToLanguageId < ActiveRecord::Migration[7.1]
  def up
    add_column :resource_scores, :language_id, :integer
    add_index :resource_scores, [:language_id, :country]

    # Migrate data from lang to language_id by joining with languages table
    execute <<-SQL
      UPDATE resource_scores
      SET language_id = languages.id
      FROM languages
      WHERE LOWER(resource_scores.lang) = LOWER(languages.code)
    SQL

    remove_index :resource_scores, [:lang, :country] if index_exists?(:resource_scores, [:lang, :country])
    remove_column :resource_scores, :lang if column_exists?(:resource_scores, :lang)
  end

  def down
    remove_index :resource_scores, [:language_id, :country] if index_exists?(:resource_scores, [:language_id, :country])
    remove_column :resource_scores, :language_id, :integer if column_exists?(:resource_scores, :language_id)

    add_column :resource_scores, :lang
    add_index :resource_scores, [:lang, :country]
  end
end
