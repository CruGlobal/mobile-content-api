class ManifestFileName < ActiveRecord::Migration[5.0]
  def change
    add_column :translations, :manifest_name, :string
  end
end
