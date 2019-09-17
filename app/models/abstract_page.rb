# frozen_string_literal:true

class AbstractPage < ActiveRecord::Base
  self.abstract_class = true

  validates :structure, presence: true, xml: {if: :structure_changed?}
end
