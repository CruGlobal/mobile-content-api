# frozen_string_literal: true

class TranslatedPage < ActiveRecord::Base
  belongs_to :page
  belongs_to :translation

  validates :value, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }

  before_save :only_non_onesky

  private

  def only_non_onesky
    raise 'Cannot be created for projects using OneSky.' if page.resource.uses_onesky?
  end
end
