# frozen_string_literal: true

class ResourceScoreSerializer < ActiveModel::Serializer
  type "resource-score"
  attributes :featured, :country, :score, :user_score_average, :user_score_count, :featured_order, :created_at, :updated_at
  attribute :lang

  belongs_to :resource
  belongs_to :language

  def lang
    object.language&.code
  end
end
