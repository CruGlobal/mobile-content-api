# frozen_string_literal: true

class S3Helper
  def self.push_translation(translation)
    language_code = translation.language.abbreviation
    resource = translation.resource

    file_name = language_code + '.zip'

    build_zip(file_name, translation)
    upload(file_name, resource)

    PageHelper.delete_temp_pages
    File.delete(file_name)
  end

  private

  def build_zip(file_name, translation)
    Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
      translation.resource.pages.each do |page|
        update_all_pages(translation, page)

        temp_file = File.open("pages/#{page.filename}", 'w')
        temp_file.puts page.structure
        temp_file.close

        zipfile.add(page.filename, "pages/#{page.filename}")
      end
    end
  end

  def update_all_pages(translation, page)
    result = PageHelper.download_translated_page(translation, page.filename)
    page.structure = result
    page.save
  rescue RestClient::ExceptionWithResponse => e
    raise e
  end

  def upload(file_name, resource)
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['GODTOOLS_V2_BUCKET'])
    obj = bucket.object("#{resource.system.name}/#{resource.abbreviation}/#{file_name}")
    obj.upload_file(file_name, acl: 'public-read')
  end
end
