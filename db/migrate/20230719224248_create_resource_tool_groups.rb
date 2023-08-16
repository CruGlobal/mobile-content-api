class CreateResourceToolGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :resource_tool_groups do |t|
      t.references :resource, null: false, foreign_key: true
      t.references :tool_group, null: false, foreign_key: true
      t.float :suggestions_weight

      t.timestamps
    end
  end
end
