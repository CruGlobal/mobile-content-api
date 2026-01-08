# frozen_string_literal: true

class ResourceScoreSerializer < ActiveModel::Serializer
  type "resource-score"
  attributes :featured, :country, :lang, :score, :user_score_average, :user_score_count, :featured_order, :created_at, :updated_at

  belongs_to :resource
end
