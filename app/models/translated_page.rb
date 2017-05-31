# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :page
  belongs_to :translation

  validates :value, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }
  validate do
    errors.add('page', 'Uses OneSky.') if page.resource.uses_onesky?
  end
end
