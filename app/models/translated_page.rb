# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :page
  belongs_to :translation

  validates :value, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }

  # TODO: don't allow this to be created if Resource.uses_onesky? is false
end
