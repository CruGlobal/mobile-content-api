# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :resource
  belongs_to :language

  validates :value, presence: true
  validates :resource, presence: true
  validates :language, presence: true
  validate do
    errors.add('resource', 'Uses OneSky.') if resource.uses_onesky?
  end
end
