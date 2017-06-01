# frozen_string_literal: true

class Page < AbstractPage
  belongs_to :resource
  has_many :onesky_phrases
  has_many :custom_pages
  has_many :translated_pages

  validates :filename, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }

  after_save :upsert_onesky_phrases, if: :resource_uses_onesky

  def parent_resource
    resource
  end

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
end
