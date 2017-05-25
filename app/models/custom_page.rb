# frozen_string_literal: true

require 'xml_util'

class CustomPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page

  validates :structure, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }

  after_validation :validate_xml

  private

  def validate_xml
    XmlUtil.validate_xml(self)
  end
end
