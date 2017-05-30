# frozen_string_literal: true

class ResourceType < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :dtd_file, presence: true

  after_validation :dtd_file_exists

  private

  def dtd_file_exists
    return if File.exist?("public/xmlns/#{dtd_file}")
    raise "ResourceType with name: #{name} does not have a DTD file in 'public/xmlns/'."
  end
end
