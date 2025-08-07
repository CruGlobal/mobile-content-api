# frozen_string_literal: true

require "xml_util"
require "crowdin"

class PageClient
  def initialize(resource, language_code)
    @resource = resource
    @language_code = language_code
  end

  def self.delete_temp_pages
    temp_dir = Dir.glob("pages/*")
    temp_dir.each { |file| File.delete(file) }
  end

  def self.delete_temp_dir(directory)
    FileUtils.remove_dir(directory)
  end
end
