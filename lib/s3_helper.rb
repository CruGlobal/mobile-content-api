# frozen_string_literal: true

require 'zip'
require 'page_helper'

class S3Helper
  def self.push_translation(translation)
    language_code = translation.language.abbreviation
    resource = translation.resource

    file_name = "version_#{translation.version}.zip"

    build_zip(file_name, translation)
    upload(file_name, resource, language_code)

    PageHelper.delete_temp_pages
    File.delete(file_name)
  end

  private_class_method
  def self.build_zip(file_name, translation)
    Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
      translation.resource.pages.each do |page|
        update_page(translation, page)

        temp_file = File.open("pages/#{page.filename}", 'w')
        temp_file.puts page.structure
        temp_file.close

        zipfile.add(page.filename, "pages/#{page.filename}")
      end
    end
  end

  private_class_method
  def self.update_page(translation, page)
    result = translation.download_translated_page(page.filename)
    page.structure = result
    page.save
  rescue RestClient::ExceptionWithResponse => e
    raise e
  end

  private_class_method
  def self.upload(file_name, resource, language_code)
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['GODTOOLS_V2_BUCKET'])
    obj = bucket.object("#{resource.system.name}/#{resource.abbreviation}/#{language_code}/#{file_name}")
    obj.upload_file(file_name, acl: 'public-read')
  end
end
