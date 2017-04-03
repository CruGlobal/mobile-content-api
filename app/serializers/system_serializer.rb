# frozen_string_literal: true

class SystemSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :resources
end
