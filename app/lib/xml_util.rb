# frozen_string_literal: true

module XmlUtil
  XMLNS_CONTENT = "https://mobile-content-api.cru.org/xmlns/content"
  XMLNS_MANIFEST = "https://mobile-content-api.cru.org/xmlns/manifest"
  XMLNS_SHAREABLE = "https://mobile-content-api.cru.org/xmlns/shareable"
  XMLNS_TRACT = "https://mobile-content-api.cru.org/xmlns/tract"
  XMLNS_TRAINING = "https://mobile-content-api.cru.org/xmlns/training"

  def self.translatable_nodes(xml)
    xpath_namespace(xml, "//content:text[@i18n-id]")
  end

  def self.translatable_node_attrs(xml)
    xml.xpath("//@*[contains(name(),'-i18n-id')]")
  end

  def self.xml_filename_sha(data)
    "#{filename_sha(data)}.xml"
  end

  def self.filename_sha(data)
    Digest::SHA256.hexdigest(data)
  end

  def self.xpath_namespace(xml, string)
    xml.xpath(string, "manifest" => XMLNS_MANIFEST, "content" => XMLNS_CONTENT, "shareable" => XMLNS_SHAREABLE, "tract" => XMLNS_TRACT, "training" => XMLNS_TRAINING)
  end

  def self.get_or_create_child(xml, ns, name)
    xml.xpath("ns:#{name}", "ns" => ns).first || xml.add_child(xml.document.create_element(name, xmlns: ns))
  end
end
