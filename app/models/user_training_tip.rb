# frozen_string_literal: true

class UserTrainingTip < ActiveRecord::Base
  validates :tool_id, uniqueness: {scope: [:user_id, :tool_id, :language_id, :tip_id], message: "combination already exists"}
  validates :tip_id, presence: true

  belongs_to :user
  belongs_to :language
  belongs_to :tool, class_name: "Resource"
end
