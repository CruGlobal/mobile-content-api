# frozen_string_literal: true

class ResourceToolGroupSerializer < ActiveModel::Serializer
  attribute :suggestions_weight, key: "suggestions-weight"

  type "tool-group-tool"

  belongs_to :resource, key: "tool"
  belongs_to :tool_group
end
