class ResourceType < ActiveRecord::Migration[5.0]
  def change
    add_column :resources, :content_type, :integer, null: true

    Resource.all.each do |r|
      r.update!(content_type: :tract)
    end

    change_column_null :resources, :content_type, false
  end
end
