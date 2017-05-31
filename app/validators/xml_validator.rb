# frozen_string_literal: true

class XmlValidator < ActiveModel::Validator
  def validate(record)
    xsd = Nokogiri::XML::Schema(File.open("public/xmlns/#{record.parent_resource.resource_type.dtd_file}"))

    errors = xsd.validate(Nokogiri::XML(record.structure))

    errors.each { |value| record.errors.add('xml', value.to_s) }
  end
end
