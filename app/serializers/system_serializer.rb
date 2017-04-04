# frozen_string_literal: true

class SystemSerializer < ActiveModel::Serializer
  type 'system'
  attributes :id, :name

  has_many :resources
end
