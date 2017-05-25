# frozen_string_literal: true

module XmlUtil
  def self.validate_xml(xml)
    xsd = Nokogiri::XML::Schema(File.open('manifest/xsd/tract.xsd'))
    doc = Nokogiri::XML(xml)

    xsd.validate(doc)
  end
end
