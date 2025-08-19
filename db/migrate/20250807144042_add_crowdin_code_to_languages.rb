class AddCrowdinCodeToLanguages < ActiveRecord::Migration[7.0]
  def change
    add_column :languages, :crowdin_code, :string
  end
end
