class RenameOneskyProjectIdToCrowdinProjectIdInResources < ActiveRecord::Migration[7.0]
  def change
    rename_column :resources, :onesky_project_id, :crowdin_project_id
  end
end
