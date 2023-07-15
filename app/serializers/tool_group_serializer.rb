# frozen_string_literal: true

class ToolGroupSerializer < ActiveModel::Serializer
  attributes :id, :name
  attribute :suggestions_weight, key: "suggestions-weight"

  type "tool-group"

  has_many :rule_languages
  has_many :rule_countries
  has_many :rule_praxis
end
