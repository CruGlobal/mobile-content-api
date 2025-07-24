# frozen_string_literal: true

class Page < AbstractPage
  belongs_to :resource, touch: true
  has_many :custom_pages

  validates :filename, presence: true, uniqueness: {scope: :resource}
  validates :position, presence: true, uniqueness: {scope: :resource}
  validates :resource, presence: true
  validates_with UsesCrowdinValidator
end
