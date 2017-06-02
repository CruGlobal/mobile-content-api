# frozen_string_literal: true
require 'digest/md5'

module XmlUtil
  def self.translatable_nodes(xml)
    xml.xpath('//content:text[@i18n-id]')
  end
end
