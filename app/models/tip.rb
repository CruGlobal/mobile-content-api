class Tip < ApplicationRecord
  belongs_to :resource

  validates :filename, presence: true, uniqueness: {scope: :resource}
  validates_with UsesOneskyValidator
end
