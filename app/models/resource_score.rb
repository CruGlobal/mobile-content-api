# frozen_string_literal: true

class ResourceScore < ApplicationRecord
  belongs_to :resource

  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 },
                    allow_nil: true
  validates :featured_order, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 },
                             allow_nil: true
  validates :default_order, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validates :resource_id, uniqueness: {
    scope: %i[country lang], message: 'should have only one score per country and language'
  }
  validates :country, presence: true
  validates :lang, presence: true
  validate :featured_has_order_assigned
  validate :featured_order_is_available, if: -> { featured && featured_order.present? }

  before_save :downcase_country_and_lang

  private

  def downcase_country_and_lang
    self.country = country.downcase if country.present?
    self.lang = lang.downcase if lang.present?
  end

  def featured_has_order_assigned
    return unless featured && featured_order.nil?

    errors.add(:featured_order, 'must be present if resource is featured')
  end

  def featured_order_is_available
    existing = ResourceScore.where(country: country, lang: lang, featured_order: featured_order)
                            .where.not(id:)
    return unless existing.exists?

    errors.add(:featured_order, 'is already taken for this country and language')
  end
end
