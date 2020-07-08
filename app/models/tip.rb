class Tip < ApplicationRecord
  belongs_to :resource

  validates :name, presence: true, uniqueness: {scope: :resource}
  validates_with UsesOneskyValidator
end
