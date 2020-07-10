# frozen_string_literal: true

class XmlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    xml_errors = xsd(record).validate(Nokogiri::XML(value))

    xml_errors.each { |e| record.errors.add(attribute, e.to_s) }
  end

  private

  def xsd(record)
    location = "public/xmlns/#{xsd_location(record)}"
    Nokogiri::XML::Schema(File.open(location))
  end

  def xsd_location(record)
    return "manifest.xsd" if record.is_a?(Resource) || record.is_a?(CustomManifest)
    return "training.xsd" if record.is_a?(Tip)
    return record.resource.resource_type.dtd_file if record.is_a?(Page) || record.is_a?(TranslatedPage)
    return record.page.resource.resource_type.dtd_file if record.is_a?(CustomPage)
    return record.tip.resource.resource_type.dtd_file if record.is_a?(CustomTip)

    raise "Object type: #{record.class} not supported."
  end
end
