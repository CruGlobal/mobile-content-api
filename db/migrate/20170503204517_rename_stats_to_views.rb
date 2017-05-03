class RenameStatsToViews < ActiveRecord::Migration[5.0]
  def change
    rename_table :stats, :views
  end
end
