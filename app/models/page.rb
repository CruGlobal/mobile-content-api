# frozen_string_literal: true

class Page < ActiveRecord::Base
  belongs_to :resource
  has_many :translation_elements
  has_many :custom_pages

  validates :filename, presence: true
  validates :structure, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }

  after_create :add_translation_elements

  private

  def add_translation_elements
    Nokogiri::XML(structure).xpath('//content:text[@i18n-id]').each do |node|
      TranslationElement.create!(page: self, onesky_phrase_id: node['i18n-id'], text: node.content)
    end
  end
end
