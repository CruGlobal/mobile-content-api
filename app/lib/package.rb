# frozen_string_literal: true

require "zip"

class Package
  XPATH_RESOURCES = %w[//@background-image
    //manifest:category/@banner
    //content:animation/@resource
    //content:button/@icon
    //content:image[not(@restrictTo='web')]/@resource
    //content:text/@start-image
    //content:text/@end-image
    //shareable:image/@resource].freeze
  XPATH_TIPS = %w[//training:tip/@id
    //tract:header/@training:tip
    //tract:call-to-action/@training:tip].freeze

  def self.s3_bucket
    s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
    bucket = s3.bucket(ENV["MOBILE_CONTENT_API_BUCKET"])
  end

  def self.s3_object(translation)
    s3_bucket.object(translation.object_name.to_s)
  end

  # for upload the zip files to s3, keep the bucket instance so we don't have to keep creating it
  def s3_bucket
    @s3_bucket ||= self.class.s3_bucket
  end

  def initialize(translation)
    @translation = translation
    @resources = []
    @tips = []
    @directory = "pages/#{SecureRandom.uuid}"
    FileUtils.mkdir_p(@directory)
  end

  def push_to_s3
    Rails.logger.info "Starting build of translation with id: #{@translation.id}"

    build_zip
    upload

    PageClient.delete_temp_dir(@directory)
  rescue => e
    PageClient.delete_temp_dir(@directory)
    raise e
  end

  private

  def build_zip
    manifest = Xml::Manifest.new(@translation)
    determine_resources(manifest.document)

    Zip::File.open("#{@directory}/#{@translation.zip_name}", Zip::File::CREATE) do |zip_file|
      add_pages(zip_file, manifest)
      add_tips(zip_file, manifest) if include_tips?
      add_attachments(zip_file, manifest)

      manifest_filename = write_manifest_to_file(manifest)
      add_file_to_zip_and_s3(zip_file, manifest_filename, "#{@directory}/#{manifest_filename}")
    end
  end

  def determine_resources(document)
    nodes = XmlUtil.xpath_namespace(document, XPATH_RESOURCES.join("|"))
    nodes.each { |node| @resources << node.content }
  end

  def determine_tips(document)
    nodes = XmlUtil.xpath_namespace(document, XPATH_TIPS.join("|"))
    nodes.each do |node|
      tip = @translation.resource.tips.find_by(name: node.content)
      raise ActiveRecord::RecordNotFound, "Tip not found: #{node.content}" unless tip
      @tips << tip
    end
  end

  def add_pages(zip_file, manifest)
    @translation.resource.pages.order(position: :asc).each do |page|
      Rails.logger.info("Adding page with id: #{page.id} to package for translation with id: #{@translation.id}")

      sha_filename = write_page_to_file(page)
      add_file_to_zip_and_s3(zip_file, sha_filename, "#{@directory}/#{sha_filename}")
      manifest.add_page(page.filename, sha_filename)
    end
  end

  def add_tips(zip_file, manifest)
    @tips.uniq.each do |tip|
      Rails.logger.info("Adding tip with id: #{tip.id} to package for translation with id: #{@translation.id}")

      sha_filename = write_tip_to_file(tip)
      add_file_to_zip_and_s3(zip_file, sha_filename, "#{@directory}/#{sha_filename}")
      manifest.add_tip(tip.name, sha_filename)
    end
  end

  def write_page_to_file(page)
    translated_page = @translation.translated_page(page.id, true)
    document = Nokogiri::XML(translated_page)
    determine_resources(document)
    determine_tips(document) if include_tips?
    sha_filename = XmlUtil.xml_filename_sha(translated_page)

    File.write("#{@directory}/#{sha_filename}", translated_page)

    sha_filename
  end

  def write_tip_to_file(tip)
    translated_tip = @translation.translated_tip(tip.id, true)
    document = Nokogiri::XML(translated_tip)
    determine_resources(document)
    sha_filename = XmlUtil.xml_filename_sha(translated_tip)

    File.write("#{@directory}/#{sha_filename}", translated_tip)

    sha_filename
  end

  def add_attachments(zip_file, manifest)
    @resources.uniq.each do |filename|
      attachment = @translation.resource.attachments.find_by(filename: filename)
      raise ActiveRecord::RecordNotFound, "Attachment not found: #{filename}" if attachment.nil?
      Rails.logger.info("Adding attachment with id: #{attachment.id} to package " \
                        "for translation with id: #{@translation.id}")

      sha_filename = save_attachment_to_file(attachment)
      add_file_to_zip_and_s3(zip_file, sha_filename, "#{@directory}/#{sha_filename}")
      manifest.add_resource(attachment.filename, sha_filename)
    end
  end

  def save_attachment_to_file(attachment)
    begin
      string_io_bytes = URI.parse(attachment.url).open.read
    rescue NoMethodError
      string_io_bytes = File.read(attachment.url)
    end
    sha_filename = attachment.sha256

    File.binwrite("#{@directory}/#{sha_filename}", string_io_bytes)
    sha_filename# + File.extname(attachment) # TODO
  end

  def write_manifest_to_file(manifest)
    filename = XmlUtil.xml_filename_sha(manifest.document.to_s)
    @translation.manifest_name = filename

    file = File.open("#{@directory}/#{filename}", "w")
    manifest.document.write_to(file)
    file.close

    filename
  end

  def upload
    Rails.logger.info("Uploading zip to OneSky for translation with id: #{@translation.id}")

    obj = self.class.s3_object(@translation)
    obj.upload_file("#{@directory}/#{@translation.zip_name}", acl: "public-read")
  end

  def include_tips?
    language_attributes = @translation.language.language_attributes.where(resource: @translation.resource)
    language_attributes.find_by(key: "include_tips")&.value == "true"
  end

  def add_file_to_zip_and_s3(zip, zip_filename, local_filename)
    zip.add(zip_filename, local_filename)
    s3_object = s3_bucket.object(zip_filename)

    # we may need to use md5 as an upload integrity check, as I can't find any examples with sha256 and everything
    # I try is failing. The base64 code here is from https://stackoverflow.com/questions/23417194/the-aws-ruby-sdk-gives-me-a-the-content-md5-you-specified-was-invalid-error-w
    # Currently, this md5 check below gives an access denied error for me, regardless of the md5 value
    #
    #content = File.read(local_filename),
    #s3_object.put(acl: "public-read", body: content, content_md5: Base64.encode64([Digest::MD5.hexdigest(content)].pack("H*")).strip)

    s3_object.put(acl: "public-read", body: File.read(local_filename), checksum_sha256: zip_filename.sub(/\.[^.]+\z/, ""))
  end
end
