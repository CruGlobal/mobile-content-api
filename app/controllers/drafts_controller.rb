# frozen_string_literal: true

require 'rest-client'
require 'digest/md5'
require 'zip'
require 'aws-sdk-rails'
require 'page_helper'

class DraftsController < ApplicationController
  def page
    resource_id = params[:resource_id]
    language_code = Language.where(id: params[:language_id]).first.abbreviation
    page_name = params[:page_id]

    begin
      result = PageHelper.download_translated_page(resource_id, page_name, language_code)
    rescue RestClient::ExceptionWithResponse => e
      result = e.response
    end

    render json: result
  end

  def create_draft
    resource = Resource.where(id: params[:resource_id]).first
    language_code = Language.where(id: params[:language_id]).first.abbreviation

    project_id = resource.one_sky_project_id

    result = 'OK'

    pages = resource.pages
    pages.each { |page|
      page_to_upload = {}

      page.translation_elements.each { |element| page_to_upload[element.id] = element.text }

      temp_file = File.open('pages/' + page.filename, 'w')
      temp_file.puts page_to_upload.to_json
      temp_file.close

      begin
        RestClient.post "https://platform.api.onesky.io/1/projects/#{project_id}/files",
                        file: File.new('pages/' + page.filename),
                        file_format: 'HIERARCHICAL_JSON',
                        api_key: ENV['ONESKY_API_KEY'],
                        timestamp: AuthHelper.epoch_time_seconds,
                        locale: language_code,
                        dev_hash: AuthHelper.dev_hash,
                        multipart: true

      rescue RestClient::ExceptionWithResponse => e
        result = e.response
      end
    }

    PageHelper.delete_temp_pages

    render json: result
  end

  def publish_draft
    language_code = Language.where(id: params[:language_id]).first.abbreviation
    resource = Resource.where(id: params[:resource_id]).first

    file_name = language_code + '.zip'

    Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
      resource.pages.each do |page|
        temp_file = File.open('pages/' + page.filename, 'w')
        temp_file.puts page.structure
        temp_file.close

        zipfile.add(page.filename, 'pages/' + page.filename)
      end
    end

    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['GODTOOLS_V2_BUCKET'])
    obj = bucket.object(resource.system.name + '/' + resource.abbreviation + '/' + file_name)
    obj.upload_file(file_name)

    PageHelper.delete_temp_pages
    File.delete(file_name)
  end
end
