# frozen_string_literal: true

class Page < ActiveRecord::Base
  belongs_to :resource
  has_many :translation_elements
  has_many :custom_pages

  validates :filename, presence: true
  validates :structure, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }

  after_save :upsert_translation_elements

  private

  def upsert_translation_elements
    Nokogiri::XML(structure).xpath('//content:text[@i18n-id]').each do |node|
      onesky_phrase_id = node['i18n-id']
      existing = TranslationElement.find_by(page: self, onesky_phrase_id: onesky_phrase_id)

      if existing
        existing.update!(text: node.content)
      else
        TranslationElement.create!(page: self, onesky_phrase_id: onesky_phrase_id, text: node.content)
      end
    end
  end
end
