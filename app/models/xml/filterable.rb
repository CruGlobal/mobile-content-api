# frozen_string_literal: true

module Xml
  module Filterable
    # Filters content in generated XML.
    #
    # @param xml [Nokorigi::XML] document
    # @param translation [Translation] The translation object we are filtering node content for
    # @return [Nokorigi::XML]
    def filter_node_content(xml, translation)
      locale = translation.language.code

      XmlUtil.filterable_nodes(xml).each do |node|
        if node.attribute_with_ns("if-locale", XmlUtil::XMLNS_PUBLISH)&.value&.split&.exclude? locale
          node.unlink
        elsif node.attribute_with_ns("if-locale-not", XmlUtil::XMLNS_PUBLISH)&.value&.split&.include? locale
          node.unlink
        end
      end

      xml
    end
  end
end
