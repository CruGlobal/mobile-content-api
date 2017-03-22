# frozen_string_literal: true
require 'rest-client'
require 'auth_helper'

class PageHelper
  def self.download_translated_page(resource_id, page_name, language_code)
    RestClient.get 'https://platform.api.onesky.io/1/projects/' + resource_id + '/translations',
                   params:
                       {
                           api_key: ENV['ONESKY_API_KEY'],
                           timestamp: AuthHelper.epoch_time_seconds,
                           dev_hash: AuthHelper.dev_hash,
                           locale: language_code,
                           source_file_name: page_name,
                           export_file_name: page_name
                       }
  end

  def self.delete_temp_pages
    temp_dir = Dir.glob('pages/*')
    temp_dir.each { |file| File.delete(file) }
  end
end
