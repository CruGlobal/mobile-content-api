# frozen_string_literal: true

module XML
  class Manifest
    # TODO: temporarily expose while we migrate manifest xml code from Package class
    attr_reader :document

    def initialize(translation)
      @translation = translation

      @document = Nokogiri::XML(@translation.resource.manifest)
      manifest_node = @document.root
      manifest_node = create_manifest if manifest_node.nil?

      add_manifest_metadata(manifest_node)
      insert_translated_name(manifest_node)
    end

    def add_page(filename, sha_filename)
      pages_node.add_child(create_file_node(XmlUtil::XMLNS_MANIFEST, 'page', filename, sha_filename))
    end

    def add_resource(filename, sha_filename)
      resources_node.add_child(create_file_node(XmlUtil::XMLNS_MANIFEST, 'resource', filename, sha_filename))
    end

    private

    def create_manifest
      @document.root = @document.create_element('manifest', xmlns: XmlUtil::XMLNS_MANIFEST)
    end

    def add_manifest_metadata(manifest_node)
      manifest_node['tool'] = @translation.resource.abbreviation
      manifest_node['locale'] = @translation.language.code
      manifest_node['type'] = @translation.resource.resource_type.name
    end

    def insert_translated_name(manifest_node)
      title_node = XmlUtil.xpath_namespace(manifest_node, 'manifest:title').first
      return if title_node.nil?

      name_node = title_node.xpath('content:text[@i18n-id]').first
      name_node.content = @translation.translated_name
    end

    def pages_node
      return @pages if @pages
      @pages = XmlUtil.get_or_create_child(@document.root, XmlUtil::XMLNS_MANIFEST, 'pages')
    end

    def resources_node
      return @resources if @resources
      @resources = XmlUtil.get_or_create_child(@document.root, XmlUtil::XMLNS_MANIFEST, 'resources')
    end

    def create_file_node(namespace, type, filename, sha_filename)
      node = @document.create_element(type, xmlns: namespace)
      node['filename'] = filename
      node['src'] = sha_filename
      node
    end
  end
end
