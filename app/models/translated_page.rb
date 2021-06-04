# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :resource, touch: true
  belongs_to :language

  validates :value, presence: true, xml: {if: :value_changed?}
  validates :resource, presence: true
  validates :language, presence: true
  validate do
    errors.add("resource", "Uses OneSky.") if resource.uses_onesky?
  end
end
