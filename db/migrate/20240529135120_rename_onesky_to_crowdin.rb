# frozen_string_literal: true

class RenameOneskyToCrowdin < ActiveRecord::Migration[7.0]
  def change
    rename_column :resources, :onesky_project_id, :crowdin_project_id

    # Also rename translated_attribute.onesky_phrase_id to crowdin_phrase_id if it exists
    if column_exists?(:translated_attributes, :onesky_phrase_id)
      rename_column :translated_attributes, :onesky_phrase_id, :crowdin_phrase_id
    end
  end
end 