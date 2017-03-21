require 'rest-client'
require 'digest/md5'
require 'page_helper'

class DraftsController < ApplicationController

  def getPage
    resourceId = params[:resourceId]
    languageCode = params[:languageId]
    pageName = params[:pageId]

    begin
      result = PageHelper::downloadTranslatedPage(resourceId, pageName, languageCode)
    rescue RestClient::ExceptionWithResponse => e
      result = e.response
    end

    render json: result

  end


  def createDraft
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
                                     timestamp: AuthHelper::getEpochTimeSeconds,
                                     locale: languageCode,
                                     dev_hash: AuthHelper::getDevHash,
                                     multipart: true
                                 }
      rescue RestClient::ExceptionWithResponse => e
        result = e.response
      end
    }

    render json: result
  end

end