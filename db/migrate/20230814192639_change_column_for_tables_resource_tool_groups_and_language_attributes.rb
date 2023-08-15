class ChangeColumnForTablesResourceToolGroupsAndLanguageAttributes < ActiveRecord::Migration[6.1]
  def change
    change_column :resource_tool_groups, :resource_id, :integer
    change_column :language_attributes, :resource_id, :integer
  end
end
