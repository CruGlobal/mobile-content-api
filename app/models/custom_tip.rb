class CustomTip < ApplicationRecord
  belongs_to :language
  belongs_to :tip

  validates :structure, presence: true, xml: {if: :structure_changed?}
  validates :language, presence: true, uniqueness: {scope: :tip}
end
