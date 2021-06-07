# frozen_string_literal: true

class CustomManifest < ApplicationRecord
  belongs_to :language
  belongs_to :resource, touch: true

  validates :resource, presence: true
  validates :language, presence: true, uniqueness: {scope: :resource}

  validates :structure, xml: true, if: :structure?
end
