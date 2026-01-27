# frozen_string_literal: true

class ResourceScore < ApplicationRecord
  MAX_FEATURED_ORDER_POSITION = 10
  MAX_SCORE = 20
  belongs_to :resource
  belongs_to :language

  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_SCORE },
                    allow_nil: true
  validates :featured_order, numericality: {
    only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_FEATURED_ORDER_POSITION
  }, allow_nil: true
  validates :resource_id, presence: true
  validates :country, presence: true
  validate :resource_uniquness_per_country_lang_and_resource_type
  validate :featured_has_order_assigned
  validate :featured_order_is_available_for_country_lang_and_resource_type, if: lambda {
    featured && featured_order.present?
  }

  before_save :downcase_country
  after_commit :clear_resource_cache
  after_commit :touch_resource, on: %i[create update]

  private

  def resource_uniquness_per_country_lang_and_resource_type
    existing = ResourceScore.joins(:resource).where(
      country: country, language_id: language_id, resource_id: resource_id, resources: { resource_type_id: resource.resource_type_id }
    ).where.not(id:)
    return unless existing.exists?

    errors.add(:resource_id, 'should have only one score per country, language and resource type')
  end

  def downcase_country
    self.country = country.downcase if country.present?
  end

  def featured_has_order_assigned
    return unless featured && featured_order.nil?

    errors.add(:featured_order, 'must be present if resource is featured')
  end

  def featured_order_is_available_for_country_lang_and_resource_type
    existing = ResourceScore.joins(:resource)
                            .where(country: country, language_id: language_id, featured_order: featured_order)
                            .where.not(id:)
                            .where(resources: { resource_type_id: resource.resource_type_id })
    return unless existing.exists?

    errors.add(:featured_order, 'is already taken for this country, language and resource type')
  end

  def clear_resource_cache
    Rails.cache.delete_matched('cache::resources/*')
    Rails.cache.delete_matched('resources/*')
  end

  def touch_resource
    resource&.touch(:updated_at)
  end
end
