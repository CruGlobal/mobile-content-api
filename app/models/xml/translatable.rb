# frozen_string_literal: true

module Xml
  module Translatable
    # Translates content in XML nodes.
    #
    # @param xml [Nokorigi::XML] document
    # @param phrases [Hash] translation phrases (from Crowdin)
    # @param strict
    # @return [Nokorigi::XML]
    # @raise [Error::TextNotFoundError]
    def translate_node_content(xml, phrases, strict = false)
      XmlUtil.translatable_nodes(xml).each do |node|
        phrase_id = node["i18n-id"]
        translated_phrase = phrases[phrase_id]

        if translated_phrase.present?
          node.content = translated_phrase
        elsif strict
          raise Error::TextNotFoundError, "Translated phrase not found: ID: #{phrase_id}, base text: #{node.content}"
        end
      end

      xml
    end

    # Translates attribute (names and) values in a XML document.
    #
    # @param xml [Nokorigi::XML] document
    # @param phrases [Hash] translation phrases (from Crowdin)
    # @param strict
    # @return [Nokorigi::XML]
    # @raise [Error::TextNotFoundError]
    def translate_node_attributes(xml, phrases, strict = false)
      XmlUtil.translatable_node_attrs(xml).each do |attribute|
        phrase_id = attribute.value
        new_name = attribute.name.gsub("-i18n-id", "")
        translated_phrase = phrases[phrase_id]

        if translated_phrase.present?
          attribute.parent.set_attribute(new_name, translated_phrase)
        elsif strict
          raise Error::TextNotFoundError, "Translated phrase not found: ID: #{phrase_id}, base text: #{attribute.value}"
        end
      end

      xml
    end
  end
end
