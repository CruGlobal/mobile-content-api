# frozen_string_literal: true

class CustomPage < AbstractPage
  belongs_to :translation
  belongs_to :page

  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }

  private

  def parent_resource
    page.resource
  end

  def page_type
    'Custom Page'
  end
end
