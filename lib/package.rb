# frozen_string_literal: true

require 'zip'
require 'page_client'
require 'xml_util'

class Package
  def self.s3_object(translation)
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['MOBILE_CONTENT_API_BUCKET'])
    bucket.object(translation.object_name.to_s)
  end

  def initialize(translation)
    @translation = translation

    @directory = "pages/#{SecureRandom.uuid}"
    FileUtils.mkdir_p(@directory)
  end

  def push_to_s3
    Rails.logger.info "Starting build of translation with id: #{@translation.id}"

    build_zip
    upload

    PageClient.delete_temp_dir(@directory)
  rescue StandardError => e
    PageClient.delete_temp_dir(@directory)
    raise e
  end

  private

  def build_zip
    @document = Nokogiri::XML(@translation.resource.manifest)
    manifest_node = load_or_create_manifest_node

    pages_node = Nokogiri::XML::Node.new('pages', @document)
    resources_node = Nokogiri::XML::Node.new('resources', @document)

    manifest_node.add_child(pages_node)
    manifest_node.add_child(resources_node)

    Zip::File.open("#{@directory}/#{@translation.zip_name}", Zip::File::CREATE) do |zip_file|
      add_pages(zip_file, pages_node)
      add_attachments(zip_file, resources_node)

      manifest_filename = write_manifest_to_file
      zip_file.add(manifest_filename, "#{@directory}/#{manifest_filename}")
    end
  end

  def load_or_create_manifest_node
    return load_manifest if @translation.resource.manifest.present?

    manifest = Nokogiri::XML::Node.new('manifest', @document)
    @document.root = manifest
    manifest
  end

  def load_manifest
    manifest_node = XmlUtil.xpath_namespace(@document, 'manifest').first
    insert_translated_name(manifest_node)
    manifest_node
  end

  def insert_translated_name(manifest_node)
    title_node = XmlUtil.xpath_namespace(manifest_node, 'title').first
    return if title_node.nil?

    name_node = title_node.xpath('content:text[@i18n-id]').first
    name_node.content = @translation.translated_name
  end

  def add_pages(zip_file, pages_node)
    @translation.resource.pages.order(position: :asc).each do |page|
      Rails.logger.info("Adding page with id: #{page.id} to package for translation with id: #{@translation.id}")

      sha_filename = write_page_to_file(page)
      zip_file.add(sha_filename, "#{@directory}/#{sha_filename}")

      add_node('page', pages_node, page.filename, sha_filename)
    end
  end

  def write_page_to_file(page)
    translated_page = @translation.translated_page(page.id, true)
    sha_filename = XmlUtil.xml_filename_sha(translated_page)

    File.write("#{@directory}/#{sha_filename}", translated_page)

    sha_filename
  end

  def add_attachments(zip_file, resources_node)
    @translation.resource.attachments.where(is_zipped: true).each do |a|
      Rails.logger.info("Adding attachment with id: #{a.id} to package for translation with id: #{@translation.id}")

      sha_filename = save_attachment_to_file(a)
      zip_file.add(sha_filename, "#{@directory}/#{sha_filename}")
      add_node('resource', resources_node, a.file.original_filename, sha_filename)
    end
  end

  def save_attachment_to_file(attachment)
    string_io_bytes = open(attachment.file.url).read
    sha_filename = attachment.sha256

    File.binwrite("#{@directory}/#{sha_filename}", string_io_bytes)
    sha_filename
  end

  def write_manifest_to_file
    filename = XmlUtil.xml_filename_sha(@document.to_s)
    @translation.manifest_name = filename

    file = File.open("#{@directory}/#{filename}", 'w')
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
    Rails.logger.info("Uploading zip to OneSky for translation with id: #{@translation.id}")

    obj = self.class.s3_object(@translation)
    obj.upload_file("#{@directory}/#{@translation.zip_name}", acl: 'public-read')
  end
end
