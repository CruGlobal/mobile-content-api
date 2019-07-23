class CustomManifestsPerLanguage < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_manifests do |t|
      t.string :structure, null: false
      t.references :resource, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
      t.timestamps
    end

    add_index :custom_manifests, [:resource_id, :language_id], unique: true
  end
end
