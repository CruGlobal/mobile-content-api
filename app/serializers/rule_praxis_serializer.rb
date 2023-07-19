# frozen_string_literal: true

class RulePraxisSerializer < ActiveModel::Serializer
  attributes :id, :openness, :confidence
  attribute :negative_rule, key: "negative-rule"

  type "tool-group-rule-praxis"

  belongs_to :tool_group
end
