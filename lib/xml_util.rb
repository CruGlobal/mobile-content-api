# frozen_string_literal: true

module XmlUtil
  def self.validate_xml(object)
    return unless object.structure_changed?

    xsd = Nokogiri::XML::Schema(File.open('manifest/xsd/tract.xsd'))
    errors = xsd.validate(Nokogiri::XML(object.structure))
    return if errors.empty?

    raise Error::XmlError, "Cannot create #{page_type(object)}, XML is invalid: #{errors}" if object.new_record?
    raise Error::XmlError, "Cannot update #{page_type(object)} with ID #{object.id}, XML is invalid: #{errors}"
  end

  def self.page_type(object)
    return 'Page' if object.instance_of?(Page)
    'Custom Page'
  end
end
