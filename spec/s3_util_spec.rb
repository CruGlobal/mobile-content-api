# frozen_string_literal: true

require 'rails_helper'
require 's3_util'

describe S3Util do
  let(:godtools) { TestConstants::GodTools }
  let(:translated_page_one) { 'this is a translated page' }
  let(:translated_page_two) { 'here is another translated page' }
  let(:translation) do
    t = Translation.find(godtools::Translations::English::ID)
    allow(t).to(receive(:translated_page).and_return(translated_page_one, translated_page_two))
    t
  end

  before do
    mock_onesky

    mock_s3(instance_double(Aws::S3::Object, upload_file: true))

    # rubocop:disable AnyInstance
    allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('public/wall.jpg')
    allow_any_instance_of(Paperclip::Attachment).to receive(:original_filename).and_return('wall.jpg')
  end

  after do
    allow(PageUtil).to receive(:delete_temp_pages).and_call_original
    PageUtil.delete_temp_pages
  end

  it 'deletes temp files after successful request' do
    push

    pages_dir_empty
  end

  it 'deletes temp files if error is raised' do
    object = instance_double(Aws::S3::Object)
    allow(object).to receive(:upload_file).and_raise(StandardError)
    mock_s3(object)

    expect { push }.to raise_error(StandardError)

    pages_dir_empty
  end

  it 'zip file contains all pages' do
    allow(PageUtil).to receive(:delete_temp_pages)

    push

    zip = Zip::File.open('pages/version_1.zip')
    expect(zip.get_entry('790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml')).not_to be_nil
    expect(zip.get_entry('5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml')).not_to be_nil
  end

  it 'zip file contains manifest' do
    allow(PageUtil).to receive(:delete_temp_pages)

    push

    zip = Zip::File.open('pages/version_1.zip')
    expect(zip.get_entry(translation.manifest_name)).not_to be_nil
  end

  it 'zip file contains all attachments' do
    allow(PageUtil).to receive(:delete_temp_pages)

    push

    zip = Zip::File.open('pages/version_1.zip')
    expect(zip.get_entry('073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd')).not_to be_nil
  end

  context 'manifest' do
    let(:expected) do
      '<?xml version="1.0"?>
<manifest>
  <pages>
    <page filename="04_ThirdPoint.xml" src="790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml"/>
    <page filename="13_FinalPage.xml" src="5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml"/>
  </pages>
  <resources>
    <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd"/>
  </resources>
</manifest>
'
    end

    it 'builds a manifest with names of all pages in order' do
      allow(PageUtil).to receive(:delete_temp_pages)

      push

      manifest = Nokogiri::XML(File.open("pages/#{translation.manifest_name}"))
      expect(manifest.to_s).to eq(expected)
    end
  end

  it 'always uses strict mode' do
    push

    expect(translation).not_to(have_received(:translated_page).with(any_args, false))
  end

  private

  def pages_dir_empty
    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  def mock_s3(object)
    bucket = instance_double(Aws::S3::Bucket, object: object)
    s3 = instance_double(Aws::S3::Resource, bucket: bucket)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)
  end

  def mock_onesky
    onesky_project_id = Resource.find(godtools::ID).onesky_project_id
    allow(RestClient).to receive(:get)
      .with("https://platform.api.onesky.io/1/projects/#{onesky_project_id}/translations", any_args)
      .and_return('{ "1":"value" }')
  end

  def push
    s3_util = S3Util.new(translation)
    s3_util.push_translation
  end
end
