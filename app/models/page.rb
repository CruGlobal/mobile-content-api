# frozen_string_literal: true

class Page < AbstractPage
  belongs_to :resource
  has_many :custom_pages

  validates :filename, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }
end
