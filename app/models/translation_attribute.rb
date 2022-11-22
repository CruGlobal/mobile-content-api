class TranslationAttribute < ApplicationRecord
  belongs_to :translation

  validates :value, presence: true
end
