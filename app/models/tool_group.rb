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
end
