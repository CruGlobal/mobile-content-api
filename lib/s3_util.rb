# frozen_string_literal: true

require 'zip'
require 'page_util'
require 'xml_util'

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
    @document = Nokogiri::XML::Document.parse(@translation.resource.manifest)
    manifest_node = load_or_create_manifest_node

    pages_node = Nokogiri::XML::Node.new('pages', @document)
    resources_node = Nokogiri::XML::Node.new('resources', @document)

    manifest_node.add_child(pages_node)
    manifest_node.add_child(resources_node)

    Zip::File.open("pages/#{@zip_file_name}", Zip::File::CREATE) do |zip_file|
      add_pages(zip_file, pages_node)
      add_attachments(zip_file, resources_node)

      manifest_filename = write_manifest_to_file
      zip_file.add(manifest_filename, "pages/#{manifest_filename}")
    end
  end

  def load_or_create_manifest_node
    return load_manifest if @translation.resource.manifest.present?

    manifest = Nokogiri::XML::Node.new('manifest', @document)
    @document.root = manifest
    manifest
  end

  def load_manifest
    manifest_node = @document.xpath('/m:manifest', 'm' => 'https://mobile-content-api.cru.org/xmlns/manifest').first
    insert_translated_name(manifest_node)
    manifest_node
  end

  def insert_translated_name(manifest_node)
    title_node = manifest_node.xpath('t:title', 't' => 'https://mobile-content-api.cru.org/xmlns/manifest').first
    return if title_node.nil?

    name_node = title_node.xpath('content:text[@i18n-id]').first
    name_node.content = @translation.translated_name
  end

  def add_pages(zip_file, pages_node)
    @translation.resource.pages.order(position: :asc).each do |page|
      sha_filename = write_page_to_file(page)
      zip_file.add(sha_filename, "pages/#{sha_filename}")

      add_node('page', pages_node, page.filename, sha_filename)
    end
  end

  def write_page_to_file(page)
    translated_page = @translation.translated_page(page.id, true)
    sha_filename = XmlUtil.xml_filename_sha(translated_page)

    File.write("pages/#{sha_filename}", translated_page)

    sha_filename
  end

  def add_attachments(zip_file, resources_node)
    @translation.resource.attachments.where(is_zipped: true).each do |a|
      string_io_bytes = open(a.file.url).read
      sha_filename = a.sha256

      File.binwrite("pages/#{sha_filename}", string_io_bytes)

      zip_file.add(sha_filename, "pages/#{sha_filename}")
      add_node('resource', resources_node, a.file.original_filename, sha_filename)
    end
  end

  def write_manifest_to_file
    filename = XmlUtil.xml_filename_sha(@document.to_s)
    @translation.manifest_name = filename

    file = File.open("pages/#{filename}", 'w')
    @document.write_to(file)
    file.close

    filename
  end

  def add_node(type, parent, filename, sha_filename)
    node = Nokogiri::XML::Node.new(type, @document)
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
