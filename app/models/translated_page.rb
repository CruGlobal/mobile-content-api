# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :page
  belongs_to :translation

  validates :value, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }
end
