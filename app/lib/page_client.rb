# frozen_string_literal: true

require "xml_util"
require "crowdin"

class PageClient
  def initialize(resource, language_code)
    @resource = resource
    @language_code = language_code
  end

  # Upload functionality has been removed as we only download translations from Crowdin

  def self.delete_temp_pages
    temp_dir = Dir.glob("pages/*")
    temp_dir.each { |file| File.delete(file) }
  end

  def self.delete_temp_dir(directory)
    FileUtils.remove_dir(directory)
  end

  private

  # All upload/push methods have been removed as we only download from Crowdin
end
