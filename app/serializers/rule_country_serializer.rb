# frozen_string_literal: true

class RuleCountrySerializer < ActiveModel::Serializer
  attributes :id, :countries
  attribute :negative_rule, key: "negative-rule"

  type "tool-group-rule-country"

  belongs_to :tool_group
end
