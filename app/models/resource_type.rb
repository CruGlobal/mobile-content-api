# frozen_string_literal: true

class ResourceType < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :dtd_file, presence: true
  validate do
    errors.add('dtd-file', 'Does not exist.') unless File.exist?("public/xmlns/#{dtd_file}")
  end
end
