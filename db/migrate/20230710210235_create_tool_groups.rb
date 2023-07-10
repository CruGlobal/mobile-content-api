class CreateToolGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :tool_groups do |t|
      t.string :name
      t.float :suggestions_weight

      t.timestamps
    end
  end
end
