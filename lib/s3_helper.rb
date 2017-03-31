# frozen_string_literal: true

require 'zip'
require 'page_helper'

class S3Helper
  def initialize(translation)
    @translation = translation
    @zip_file_name = "version_#{@translation.version}.zip"
  end

  def push_translation
    build_zip
    upload

    PageHelper.delete_temp_pages
    File.delete(@zip_file_name)
  end

  private

  def build_zip
    Zip::File.open(@zip_file_name, Zip::File::CREATE) do |zip_file|
      @translation.resource.pages.each do |page|
        update_page(page)

        temp_file = File.open("pages/#{page.filename}", 'w')
        temp_file.puts page.structure
        temp_file.close

        zip_file.add(page.filename, "pages/#{page.filename}")
      end
    end
  end

  def update_page(page)
    result = @translation.download_translated_page(page.filename)
    page.structure = result
    page.save
  end

  def upload
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['GODTOOLS_V2_BUCKET'])
    obj = bucket.object("#{@translation.resource.system.name}/#{@translation.resource.abbreviation}"\
                        "/#{@translation.language.abbreviation}/#{@zip_file_name}")
    obj.upload_file(@zip_file_name, acl: 'public-read')
  end
end
