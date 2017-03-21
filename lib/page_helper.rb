require 'rest-client'
require 'auth_helper'

class PageHelper

  def self.downloadTranslatedPage(resourceId, pageName, languageCode)

    return RestClient.get 'https://platform.api.onesky.io/1/projects/' + resourceId + '/translations',
                   {
                       params:
                           {
                               api_key: ENV['ONESKY_API_KEY'],
                               timestamp: AuthHelper::getEpochTimeSeconds,
                               dev_hash: AuthHelper::getDevHash,
                               locale: languageCode,
                               source_file_name: pageName,
                               export_file_name: pageName
                           }
                   }
  end

  def self.deleteTempPages

    tempDir = Dir.glob('pages/*')
    tempDir.each { |file| File.delete(file) }

  end

end