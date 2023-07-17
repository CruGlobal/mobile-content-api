class RulePraxi < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:openness, :confidence], message: "combination already exists"}

  # IMPLEMENT NEXT VALIDATIONS
  #   openness: Array<Int> (int values 1-5, can have multiple values set)
  #   confidence: Array<Int> (int values 1-5, can have multiple values set)
end
