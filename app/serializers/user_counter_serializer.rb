# frozen_string_literal: true

class UserCounterSerializer < ActiveModel::Serializer
  type "user-counter"
  attributes :id, :count, :decayed_count, :last_decay
  attribute :values, if: :has_values?

  def id
    object.counter_name
  end

  def has_values?
    object.values.any?
  end
end
