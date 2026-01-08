class ResourceDefaultOrder < ApplicationRecord
  belongs_to :resource

  validates :position, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :resource_id, presence: true, uniqueness: {scope: :lang, message: "should have only one resource per language"}
  validates :lang, presence: true

  before_save :downcase_lang
  after_commit :clear_resource_cache

  private

  def downcase_lang
    self.lang = lang.downcase if lang.present?
  end

  def clear_resource_cache
    Rails.cache.delete_matched("cache::resources/*")
    Rails.cache.delete_matched("resources/*")
  end
end
