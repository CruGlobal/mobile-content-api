class AddDirectionToLanguages < ActiveRecord::Migration[5.0]
  def change
    add_column :languages, :direction, :string, default => "ltr"
  end
end
