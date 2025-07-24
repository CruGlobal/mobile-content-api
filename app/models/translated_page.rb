# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :resource, touch: true
  belongs_to :language

  validates :value, presence: true, xml: {if: :value_changed?}
  validates :resource, presence: true
  validates :language, presence: true
  validate do
    errors.add("resource", "Uses CrowdIn.") if resource.uses_crowdin?
  end
end
