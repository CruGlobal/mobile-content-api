class ResourceDefaultOrder < ApplicationRecord
  MAX_DEFAULT_ORDER_POSITION = 9
  belongs_to :resource
  belongs_to :language

  validates :resource_id, presence: true,
                          uniqueness: { scope: :language_id,
                                        message: 'should have only one ResourceDefaultOrder per language' }
  validates :language, presence: true
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 1,
                                       less_than_or_equal_to: MAX_DEFAULT_ORDER_POSITION }

  validate :unique_position_per_language_and_resource_type

  after_commit :clear_resource_cache
  after_commit :touch_resource, on: %i[create update]

  private

  def unique_position_per_language_and_resource_type
    existing = ResourceDefaultOrder.joins(:resource)
                                   .where(language_id: language_id, position: position)
                                   .where(resources: { resource_type_id: resource.resource_type_id })
                                   .where.not(id:)
    return unless existing.exists?

    errors.add(:position, 'is already taken for this language and resource type')
  end

  def clear_resource_cache
    Rails.cache.delete_matched('cache::resources/*')
    Rails.cache.delete_matched('resources/*')
  end

  def touch_resource
    resource&.touch(:updated_at)
  end
end
