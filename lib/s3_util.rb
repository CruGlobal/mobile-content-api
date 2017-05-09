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

    PageUtil.delete_temp_pages
  rescue StandardError => e
    PageUtil.delete_temp_pages
    raise e
  end

  private

  def build_zip
    @document = Nokogiri::XML::Document.new
    root_node = Nokogiri::XML::Node.new('pages', @document)
    @document.root = root_node

    Zip::File.open("pages/#{@zip_file_name}", Zip::File::CREATE) do |zip_file|
      add_pages(zip_file, root_node)
      add_attachments(zip_file)

      manifest_filename = write_manifest_to_file
      zip_file.add(manifest_filename, "pages/#{manifest_filename}")
    end
  end

  def add_pages(zip_file, root_node)
    @translation.resource.pages.each do |page|
      sha_filename = write_page_to_file(page)
      zip_file.add(sha_filename, "pages/#{sha_filename}")

      add_page_node(root_node, page.filename, sha_filename)
    end
  end

  def write_page_to_file(page)
    translated_page = @translation.build_translated_page(page.id, true)
    sha_filename = "#{Digest::SHA256.hexdigest(translated_page)}.xml"

    temp_file = File.open("pages/#{sha_filename}", 'w')
    temp_file.puts(translated_page)
    temp_file.close

    sha_filename
  end

  def add_attachments(zip_file)
    @translation.resource.attachments.each do |a|
      file = Tempfile.new
      url = a.file.url
      string_io = open(url)
      file.binmode
      file.write(string_io.read)
      file.close
      path = file.path
      zip_file.add(a.key, path)
      # TODO: need to delete
      # TODO: need to add to manifest
      # TODO: need to sha
    end
  end

  def write_manifest_to_file
    filename = "#{Digest::SHA256.hexdigest(@document.to_s)}.xml"
    @translation.manifest_name = filename

    file = File.open("pages/#{filename}", 'w')
    @document.write_to(file)
    file.close

    filename
  end

  def add_page_node(parent, filename, sha_filename)
    node = Nokogiri::XML::Node.new('page', @document)
    node['filename'] = filename
    node['src'] = sha_filename
    parent.add_child(node)
  end

  def upload
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['MOBILE_CONTENT_API_BUCKET'])
    obj = bucket.object("#{@translation.resource.system.name}/#{@translation.resource.abbreviation}"\
                        "/#{@translation.language.code}/#{@zip_file_name}")
    obj.upload_file("pages/#{@zip_file_name}", acl: 'public-read')
  end
end
