# frozen_string_literal: true

class UserCounterSerializer < ActiveModel::Serializer
  type "user-counter"
  attributes :id, :count, :decayed_count, :last_decay

  def id
    object.counter_name
  end
end
