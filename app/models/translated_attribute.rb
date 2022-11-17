class TranslatedAttribute < ApplicationRecord
  belongs_to :resource

  validates :key, uniqueness: { scope: :resource_id }
end
