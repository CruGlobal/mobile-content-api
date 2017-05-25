# frozen_string_literal: true

require 'xml_util'

class Page < ActiveRecord::Base
  belongs_to :resource
  has_many :onesky_phrases
  has_many :custom_pages
  has_many :translated_pages

  validates :filename, presence: true
  validates :structure, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }

  after_validation :validate_xml, if: :structure_changed?
  after_save :upsert_onesky_phrases, if: :resource_uses_onesky

  private

  def resource_uses_onesky
    resource.uses_onesky?
  end

  def upsert_onesky_phrases
    Nokogiri::XML(structure).xpath('//content:text[@i18n-id]').each do |node|
      onesky_id = node['i18n-id']
      existing = OneskyPhrase.find_by(page: self, onesky_id: onesky_id)

      if existing
        existing.update!(text: node.content)
      else
        OneskyPhrase.create!(page: self, onesky_id: onesky_id, text: node.content)
      end
    end
  end

  def validate_xml
    errors = XmlUtil.validate_xml(structure)
    raise "Page with filename '#{filename}' has invalid XML: #{errors}" unless errors.empty?
  end
end
