# frozen_string_literal:true

class AbstractPage < ActiveRecord::Base
  self.abstract_class = true

  validates :structure, presence: true
  validates_with XmlValidator, if: :structure_changed?
end
