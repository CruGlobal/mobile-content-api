class TranslatedAttribute < ApplicationRecord
  belongs_to :resource

  validates :key, uniqueness: {scope: :resource_id}
  validates :key, presence: true
  validates :crowdin_phrase_id, presence: true
end
