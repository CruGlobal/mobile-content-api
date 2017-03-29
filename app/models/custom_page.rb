# frozen_string_literal: true

class CustomPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page

  validates :page, uniqueness: { scope: :translation, message: 'Only one page/translation combo allowed.' }

  def self.upsert(translation, page_id, structure)
    create!(translation: translation, page_id: page_id, structure: structure)
    :created
  rescue
    existing = find_by(translation_id: translation.id, page_id: page_id)
    existing.update(structure: structure)
    :no_content
  end
end
