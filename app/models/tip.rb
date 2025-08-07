class Tip < ApplicationRecord
  belongs_to :resource, touch: true
  has_many :custom_tips

  validates :name, presence: true, uniqueness: {scope: :resource}
  validates :structure, presence: true, xml: {if: :structure_changed?}
  validates_with UsesCrowdinValidator
end
