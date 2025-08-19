# frozen_string_literal: true

module Xml
  class Manifest
    include Filterable
    include Translatable

    attr_reader :document

    def initialize(translation)
      @translation = translation

      @document = Nokogiri::XML(@translation.resolve_manifest)
      @document.root = create_manifest if @document.root.nil?

      manifest_node = @document.root
      add_manifest_metadata(manifest_node)

      filter_node_content(@document, @translation)
      phrases = manifest_translated_phrases(manifest_node)
      translate_node_content(@document, phrases, true)
      translate_node_attributes(@document, phrases, true)
    end

    def add_page(filename, sha_filename)
      pages_node.add_child(create_file_node(XmlUtil::XMLNS_MANIFEST, "page", filename, sha_filename))
    end

    def add_tip(name, sha_filename)
      tips_node.add_child(create_file_node(XmlUtil::XMLNS_MANIFEST, "tip", name, sha_filename, "id"))
    end

    def add_resource(filename, sha_filename)
      resources_node.add_child(create_file_node(XmlUtil::XMLNS_MANIFEST, "resource", filename, sha_filename))
    end

    private

    def create_manifest
      @document.root = @document.create_element("manifest",
        "xmlns" => XmlUtil::XMLNS_MANIFEST,
        "xmlns:content" => XmlUtil::XMLNS_CONTENT)
    end

    def add_manifest_metadata(manifest_node)
      manifest_node["tool"] = @translation.resource.abbreviation
      manifest_node["locale"] = @translation.language.code
      manifest_node["type"] = @translation.resource.resource_type.name
    end

    def manifest_translated_phrases(manifest_node)
      phrases = @translation.download_translated_phrases
      # backwards compatibility with manifest name translation:
      if (i18n_id = title_i18n_id(manifest_node))
        phrases = phrases.dup
        phrases[i18n_id] = @translation.translated_name
      end

      phrases
    end

    def title_i18n_id(manifest_node)
      title_node = XmlUtil.xpath_namespace(manifest_node, "manifest:title").first
      return if title_node.nil?

      name_node = title_node.xpath("content:text[@i18n-id]")&.first
      return if name_node.nil?

      name_node.attributes["i18n-id"].value
    end

    def pages_node
      return @pages if @pages
      @pages = XmlUtil.get_or_create_child(@document.root, XmlUtil::XMLNS_MANIFEST, "pages")
    end

    def tips_node
      return @tips if @tips
      @tips = XmlUtil.get_or_create_child(@document.root, XmlUtil::XMLNS_MANIFEST, "tips")
    end

    def resources_node
      return @resources if @resources
      @resources = XmlUtil.get_or_create_child(@document.root, XmlUtil::XMLNS_MANIFEST, "resources")
    end

    def create_file_node(namespace, type, filename, sha_filename, filename_key = "filename")
      node = @document.create_element(type, xmlns: namespace)
      node[filename_key] = filename
      node["src"] = sha_filename
      node
    end
  end
end
