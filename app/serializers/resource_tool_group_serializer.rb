# frozen_string_literal: true

class ResourceToolGroupSerializer < ActiveModel::Serializer
  attributes :resource_id, :tool_group
  attribute :suggestions_weight, key: "suggestions-weight"

  type "tool-group-tool"

  belongs_to :resource
  belongs_to :tool_group
end
