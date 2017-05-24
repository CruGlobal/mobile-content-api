class ResourceManifest < ActiveRecord::Migration[5.0]
  def change
    add_column :resources, :manifest, :string, null: true
  end
end
