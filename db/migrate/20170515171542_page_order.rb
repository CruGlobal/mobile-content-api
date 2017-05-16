class PageOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :position, :integer, null: true

    Page.all.each do |p|
      p.update!(position: p.id) #assign it a value we know is unique
    end

    change_column_null :pages, :position, false
    add_index :pages, [:position, :resource_id], unique: true
  end
end
