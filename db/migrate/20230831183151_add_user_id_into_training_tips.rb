class AddUserIdIntoTrainingTips < ActiveRecord::Migration[6.1]
  def change
    add_column :training_tips, :user_id, :integer
  end
end
