# frozen_string_literal: true

require 'equivalent-xml'
require 'rails_helper'
require 'package'
require 'xml_util'

describe Package do
  let(:translated_page_one) { 'this is a translated page' }
  let(:translated_page_two) { 'here is another translated page' }
  let(:translation) do
    t = Translation.find(1)
    allow(t).to(receive(:translated_page).and_return(translated_page_one, translated_page_two))
    t
  end

  let(:guid) { '32ef5884-9004-47d8-9285-bb5b2205e554' }
  let(:directory) { "pages/#{guid}" }

  before do
    mock_onesky

    mock_s3(instance_double(Aws::S3::Object, upload_file: true), translation)

    # rubocop:disable AnyInstance
    allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return("#{fixture_path}/wall.jpg")
    allow_any_instance_of(Paperclip::Attachment).to receive(:original_filename).and_return('wall.jpg')

    allow(SecureRandom).to receive(:uuid).and_return(guid)
  end

  after do
    if Dir.exist?(directory)
      allow(PageClient).to receive(:delete_temp_dir).and_call_original
      PageClient.delete_temp_dir(directory)
    end
  end

  it 'deletes temp directory after successful request' do
    push

    pages_dir_nil
  end

  it 'deletes temp directory if error is raised' do
    object = instance_double(Aws::S3::Object)
    allow(object).to receive(:upload_file).and_raise(StandardError)
    mock_s3(object, translation)

    expect { push }.to raise_error(StandardError)

    pages_dir_nil
  end

  it 'zip file contains all pages' do
    mock_dir_deletion

    push

    expect_exists('790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml')
    expect_exists('5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml')
  end

  it 'zip file contains manifest' do
    mock_dir_deletion

    push

    expect_exists(translation.manifest_name)
  end

  it 'zip file contains all attachments' do
    mock_dir_deletion

    push

    expect_exists('073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd')
  end

  context 'manifest' do
    let(:pages) do
      Nokogiri::XML('<pages xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <page filename="04_ThirdPoint.xml" src="790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml"/>
        <page filename="13_FinalPage.xml" src="5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml"/>
      </pages>').root
    end
    let(:resources) do
      Nokogiri::XML('<resources xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd"/>
      </resources>').root
    end
    let(:title) { 'this is the kgp' }

    before do
      mock_dir_deletion
    end

    it 'contains all pages in order' do
      push

      result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), '//manifest:pages').first
      expect(result).to be_equivalent_to(pages)
    end

    it 'contains all resources' do
      push

      result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), '//manifest:resources').first
      expect(result).to be_equivalent_to(resources)
    end

    it 'contains translated title' do
      allow(translation).to receive(:translated_name).and_return(title)

      push

      manifest = load_xml(translation.manifest_name)
      result = manifest.xpath('//content:text[@i18n-id=\'89a09d72-114f-4d89-a72c-ca204c796fd9\']').first
      expect(result.content).to eq(title)
    end

    context 'resource does not have a manifest file' do
      let(:translation) do
        t = Translation.find(8)
        allow(t).to(receive(:translated_page).and_return(translated_page_one, translated_page_two))
        t
      end

      it 'creates manifest node' do
        push

        manifest = load_xml(translation.manifest_name)
        expect(manifest.xpath('/m:manifest', 'm' => XmlUtil::XMLNS_MANIFEST).size).to be(1)
      end
    end
  end

  it 'always uses strict mode' do
    push

    expect(translation).not_to(have_received(:translated_page).with(any_args, false))
  end

  private

  def load_xml(name)
    Nokogiri::XML(File.open("#{directory}/#{name}"))
  end

  def open_zip_file; end

  def expect_exists(filename)
    file = Zip::File.open("#{directory}/version_1.zip").get_entry(filename)
    expect(file).not_to be_nil
  end

  def pages_dir_nil
    expect(Dir.exist?(directory)).to be_falsey
  end

  def mock_onesky
    onesky_project_id = Resource.find(1).onesky_project_id
    allow(RestClient).to receive(:get)
      .with("https://platform.api.onesky.io/1/projects/#{onesky_project_id}/translations", any_args)
      .and_return('{ "1":"value" }')
  end

  def mock_dir_deletion
    allow(PageClient).to receive(:delete_temp_dir)
  end

  def push
    package = Package.new(translation)
    package.push_to_s3
  end
end
