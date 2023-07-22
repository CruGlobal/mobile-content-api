# frozen_string_literal: true

# ToolGroup model class
class ToolGroup < ApplicationRecord
  validates :name, :suggestions_weight, presence: true
  validates :name, uniqueness: true

  has_many :rule_languages, dependent: :destroy
  has_many :rule_countries, dependent: :destroy
  has_many :rule_praxes, class_name: "RulePraxis", dependent: :destroy
  has_many :resource_tool_groups
  has_many :resources, through: :resource_tool_groups

  scope :matching_countries__negative_rule_false, lambda { |country|
    where("countries @> ARRAY[?]::varchar[] AND rule_countries.negative_rule = ?", country&.upcase, false)
  }

  scope :matching_languages__negative_rule_false, lambda { |language|
    where("languages && ARRAY[?]::varchar[] AND rule_languages.negative_rule = ?", language, false)
  }

  scope :languages_not_matching__negative_rule_true, lambda { |languages|
    where("NOT ?::varchar[] <@ languages", "{#{languages.join(',')}}")
    .where("rule_languages.negative_rule = ?", true)
  }

  scope :countries_not_matching__negative_rule_true, lambda { |country|
    where.not("countries @> ARRAY[?]::varchar[]", country&.upcase)
      .where("rule_countries.negative_rule = ?", true)
  }
end
