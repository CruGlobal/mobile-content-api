class ResourceDefaultOrder < ApplicationRecord
  belongs_to :resource
  belongs_to :language

  validates :position, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :resource_id, presence: true, uniqueness: {scope: :language_id, message: "should have only one resource per language"}
  validates :language, presence: true

  after_commit :clear_resource_cache
  after_commit :touch_resource, on: [:create, :update]

  private

  def clear_resource_cache
    Rails.cache.delete_matched("cache::resources/*")
    Rails.cache.delete_matched("resources/*")
  end

  def touch_resource
    resource&.touch(:updated_at)
  end
end
