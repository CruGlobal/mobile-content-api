# frozen_string_literal: true

class CustomPage < AbstractPage
  belongs_to :language
  belongs_to :page

  validates :page, presence: true
  validates :language, presence: true, uniqueness: { scope: :page }
end
