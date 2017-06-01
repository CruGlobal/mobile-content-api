class ResourceTypeNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column_null :resources, :resource_type_id, false
  end
end
