# frozen_string_literal: true

class CustomPageSerializer < ActiveModel::Serializer
  type 'custom-page'
  attributes :id, :structure

  belongs_to :page
  belongs_to :translation
end
