# frozen_string_literal: true

class LanguageAttribute < BaseAttribute
  belongs_to :language

  validates :resource, presence: true, uniqueness: {scope: [:resource, :key]}
end
