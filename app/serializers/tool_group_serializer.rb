# frozen_string_literal: true

class ToolGroupSerializer < ActiveModel::Serializer
  attributes :id, :name
  attribute :suggestions_weight, key: "suggestions-weight"

  type "tool-group"

  has_many :tool_group_rule_languages
end
