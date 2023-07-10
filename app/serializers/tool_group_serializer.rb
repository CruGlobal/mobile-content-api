# frozen_string_literal: true

class ToolGroupSerializer < ActiveModel::Serializer
  attributes :id, :name, :suggestions_weight

  type 'tool-group'

  def type
    'tool-group'
  end
end
