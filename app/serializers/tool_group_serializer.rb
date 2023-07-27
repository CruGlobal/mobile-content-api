# frozen_string_literal: true

class ToolGroupSerializer < ActiveModel::Serializer
  attributes :id, :name
  attribute :suggestions_weight, key: "suggestions-weight"

  type "tool-group"

  has_many :rule_languages, key: "rules-language"
  has_many :rule_countries, key: "rules-country"
  has_many :rule_praxes, key: "rules-praxis"
  has_many :resource_tool_groups, key: "tools"
  has_many :resources, through: :resource_tool_groups

  def custom_rule_languages
    object.rule_languages
  end

  def custom_rule_countries
    object.rule_countries
  end

  def custom_rule_praxis
    object.rule_praxes
  end
end
