# frozen_string_literal: true

# ToolGroup model class
class ToolGroup < ApplicationRecord
  validates :name, :suggestions_weight, presence: true
  validates :name, uniqueness: true
end
