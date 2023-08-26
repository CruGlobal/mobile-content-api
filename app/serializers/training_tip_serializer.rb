# frozen_string_literal: true

class TrainingTipSerializer < ActiveModel::Serializer
  attributes :id, :tool, :locale
  attribute :tip_id, key: "tip-id"
  attribute :is_completed, key: "is-completed"

  type "training-tip"
end
