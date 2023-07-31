# frozen_string_literal: true

# app/models/resource_tool_group.rb
class ResourceToolGroup < ApplicationRecord
  belongs_to :resource
  belongs_to :tool_group

  validates :tool_group_id, uniqueness: {scope: [:resource_id], message: "combination already exists"}
end
