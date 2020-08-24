# frozen_string_literal: true

class TipSerializer < ActiveModel::Serializer
  type "tip"
  attributes :id, :name, :structure

  belongs_to :resource

  has_many :custom_tips
end
