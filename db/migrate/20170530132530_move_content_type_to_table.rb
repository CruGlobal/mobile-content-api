class MoveContentTypeToTable < ActiveRecord::Migration[5.0]
  def change
    create_table :resource_types do |t|
      t.string :name, index: {unique: true}, null: false
      t.string :dtd_file, null: false
    end

    add_reference :resources, :resource_type, index: true, null: true
    add_foreign_key :resources, :resource_types

    remove_column :resources, :content_type, :integer
  end
end
