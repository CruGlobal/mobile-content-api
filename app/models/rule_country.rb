class RuleCountry < ApplicationRecord
  belongs_to :tool_group
  
  validates :tool_group_id, uniqueness: { scope: [:countries, :negative_rule], message: "combination already exists" }
end
