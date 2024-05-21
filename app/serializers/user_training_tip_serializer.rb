# frozen_string_literal: true

class UserTrainingTipSerializer < ActiveModel::Serializer
  attribute :tip_id, key: "tip-id"
  attribute :is_completed, key: "is-completed"

  type "training-tip"

  belongs_to :language
  belongs_to :tool
end
