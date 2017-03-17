require 'rest-client'
require 'digest/md5'

class DraftsController < ApplicationController

  def getPage
    resourceId = params[:resourceId]
    languageCode = params[:languageId]
    pageName = params[:pageId]

    epochTime = Time.new.strftime('%s')

    begin
      result = RestClient.get 'https://platform.api.onesky.io/1/projects/' + resourceId + '/translations',
                                {params: {
                                    api_key: ENV['ONESKY_API_KEY'],
                                    timestamp: epochTime,
                                    dev_hash: Digest::MD5.hexdigest(epochTime + ENV['ONESKY_API_SECRET']),
                                    locale: languageCode,
                                    source_file_name: pageName,
                                    export_file_name: pageName
                                }
                                }
    rescue RestClient::ExceptionWithResponse => e
      result = e.response
    end

    render json: result

  end


  def createDraft
    epochTime = Time.new.strftime('%s')

    resourceId = params[:resourceId]
    languageCode = params[:languageId]

    result = "OK"

    pages = Page.all
    pages.each { |page|
      pageToUpload = Hash.new

      page.translation_elements.each {|element| pageToUpload[element.id] = element.text}

      tempFile = File.open('pages/' + page.filename, 'w')
      tempFile.puts pageToUpload.to_json
      tempFile.close

      begin
        RestClient.post 'https://platform.api.onesky.io/1/projects/' + resourceId + '/files',
                                 {
                                     file: File.new('pages/' + page.filename),
                                     file_format: 'HIERARCHICAL_JSON',
                                     api_key: ENV['ONESKY_API_KEY'],
                                     timestamp: epochTime,
                                     locale: languageCode,
                                     dev_hash: Digest::MD5.hexdigest(epochTime + ENV['ONESKY_API_SECRET']),
                                     multipart: true
                                 }
      rescue RestClient::ExceptionWithResponse => e
        result = e.response
      end
    }

    render json: result
  end

end