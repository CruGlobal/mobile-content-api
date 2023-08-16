class RuleLanguage < ApplicationRecord
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:languages, :negative_rule], message: "combination already exists"}
end
