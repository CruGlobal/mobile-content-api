# frozen_string_literal: true

class TranslationElementSerializer < ActiveModel::Serializer
  attributes :id, :page_order, :text

  belongs_to :page
end
