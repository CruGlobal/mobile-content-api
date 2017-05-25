# frozen_string_literal: true

require 'xml_util'

class CustomPage < ActiveRecord::Base
  belongs_to :translation
  belongs_to :page

  validates :structure, presence: true
  validates :page, presence: true
  validates :translation, presence: true, uniqueness: { scope: :page }

  after_validation :validate_xml, if: :structure_changed?

  private

  def validate_xml
    errors = XmlUtil.validate_xml(structure)
    return if errors.empty?

    raise "Cannot create Custom Page, XML is invalid: #{errors}" if new_record?
    raise "Cannot update Custom Page with ID #{id}, XML is invalid: #{errors}"
  end
end
