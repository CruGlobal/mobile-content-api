# frozen_string_literal: true

class ToolGroupRuleLanguageSerializer < ActiveModel::Serializer
  attributes :id, :languages
  attribute :negative_rule, key: "negative-rule"

  type "tool-group-rule-language"

  belongs_to :tool_group
end
