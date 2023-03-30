class AddGrMasterPersonId < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :gr_master_person_id, :string
  end
end
