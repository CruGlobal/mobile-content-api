# frozen_string_literal: true

# Serializer for ResourceScore model
class ResourceScoreSerializer < ActiveModel::Serializer
  type "resource-score"
  attributes :featured, :country, :lang, :score, :user_score_average, :user_score_count, :featured_order

  belongs_to :resource
end
