# frozen_string_literal: true

require 'zip'
require 'page_util'

class S3Util
  def initialize(translation)
    @translation = translation
    @zip_file_name = "version_#{@translation.version}.zip"
  end

  def push_translation
    build_zip
    upload

    delete_temp_files
  rescue StandardError => e
    delete_temp_files
    raise e
  end

  private

  def delete_temp_files
    PageUtil.delete_temp_pages
    File.delete(@zip_file_name)
  end

  def build_zip
    doc = Nokogiri::XML::Document.new
    root_node = Nokogiri::XML::Node.new('pages', doc)
    doc.root = root_node

    Zip::File.open(@zip_file_name, Zip::File::CREATE) do |zip_file|
      @translation.resource.pages.each do |page|
        write_temp_file(page)
        zip_file.add(page.filename, "pages/#{page.filename}")

        add_page_node(doc, root_node, page.filename)
      end
    end

    file = File.open('pages/manifest.xml', 'w')
    doc.write_to(file)
    file.close
  end

  def write_temp_file(page)
    temp_file = File.open("pages/#{page.filename}", 'w')
    temp_file.puts(@translation.build_translated_page(page.id))
    temp_file.close
  end

  def add_page_node(doc, parent, filename)
    node = Nokogiri::XML::Node.new('page', doc)
    node['src'] = filename
    parent.add_child(node)
  end

  def upload
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['MOBILE_CONTENT_API_BUCKET'])
    obj = bucket.object("#{@translation.resource.system.name}/#{@translation.resource.abbreviation}"\
                        "/#{@translation.language.code}/#{@zip_file_name}")
    obj.upload_file(@zip_file_name, acl: 'public-read')
  end
end
