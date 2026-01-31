# frozen_string_literal: true

class ResourceScore < ApplicationRecord
  MAX_FEATURED_ORDER_POSITION = 9
  MAX_SCORE = 20
  belongs_to :resource
  belongs_to :language

  validates :resource_id, presence: true
  validates :country, presence: true
  validates :language, presence: true
  validates :featured_order, numericality: {
    only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_FEATURED_ORDER_POSITION
  }, allow_nil: true
  validates :score, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_SCORE},
    allow_nil: true

  validate :unique_resource_score_per_country_and_language
  validate :unique_featured_order_per_country_language_and_resource_type, if: lambda {
    featured && featured_order.present?
  }
  validate :featured_and_featured_order_consistency

  before_save :downcase_country
  after_commit :clear_resource_cache
  after_commit :touch_resource, on: %i[create update]

  private

  def downcase_country
    self.country = country.downcase if country.present?
  end

  def unique_resource_score_per_country_and_language
    existing = ResourceScore.where(
      country: country,
      language_id: language_id,
      resource_id: resource_id
    ).where.not(id:)
    return unless existing.exists?

    errors.add(:resource_id, "should have only one ResourceScore per country and language")
  end

  def unique_featured_order_per_country_language_and_resource_type
    existing = ResourceScore.joins(:resource)
      .where(country: country, language_id: language_id, featured_order: featured_order)
      .where(resources: {resource_type_id: resource.resource_type_id})
      .where.not(id:)
    return unless existing.exists?

    errors.add(:featured_order, "is already taken for this country, language and resource type")
  end

  def featured_and_featured_order_consistency
    if featured && featured_order.nil?
      errors.add(:featured_order, "must be present if resource is featured")
    elsif !featured && featured_order.present?
      errors.add(:featured, "must be true if a featured_order is assigned")
    end
  end

  def clear_resource_cache
    Rails.cache.delete_matched("cache::resources/*")
    Rails.cache.delete_matched("resources/*")
  end

  def touch_resource
    resource&.touch(:updated_at)
  end
end
