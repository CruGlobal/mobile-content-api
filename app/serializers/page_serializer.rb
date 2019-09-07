# frozen_string_literal: true

class PageSerializer < ActiveModel::Serializer
  type "page"
  attributes :id, :filename, :structure

  belongs_to :resource

  has_many :custom_pages
end
