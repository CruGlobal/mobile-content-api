# frozen_string_literal:true

class AbstractPage < ActiveRecord::Base
  self.abstract_class = true

  validates :structure, presence: true

  after_validation :validate_page_xml, if: :structure_changed?

  private

  def validate_page_xml
    errors = validation_errors
    return if errors.empty?

    raise_error(errors)
  end

  def validation_errors
    xsd = Nokogiri::XML::Schema(File.open("public/xmlns/#{parent_resource.resource_type.dtd_file}"))
    xsd.validate(Nokogiri::XML(structure))
  end

  def raise_error(errors)
    raise Error::XmlError, "Cannot create #{page_type}, XML is invalid: #{errors}" if new_record?
    raise Error::XmlError, "Cannot update #{page_type} with ID #{id}, XML is invalid: #{errors}"
  end
end
