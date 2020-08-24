# frozen_string_literal: true

class CustomTipSerializer < ActiveModel::Serializer
  type "custom-tip"
  attributes :id, :structure

  belongs_to :tip
  belongs_to :language
end
