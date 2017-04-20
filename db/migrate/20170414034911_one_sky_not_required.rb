class OneSkyNotRequired < ActiveRecord::Migration[5.0]
  def change
    change_column_null :resources, :onesky_project_id, true
  end
end
