# frozen_string_literal: true

require 'rails_helper'
require 's3_util'

describe S3Util do
  let(:godtools) { TestConstants::GodTools }

  before(:each) do
    mock_onesky
    @translation = Translation.find(godtools::Translations::English::ID)
    allow_any_instance_of(Paperclip::Attachment).to receive(:url).and_return('public/wall.jpg')
    allow_any_instance_of(Paperclip::Attachment).to receive(:original_filename).and_return('wall.jpg')
  end

  it 'deletes temp files after successful request' do
    mock_translation_build
    mock_s3(double(upload_file: true))

    push

    pages_dir_empty
  end

  it 'deletes temp files if error is raised' do
    mock_translation_build
    object = double
    allow(object).to receive(:upload_file).and_raise(StandardError)
    mock_s3(object)

    expect { push }.to raise_error(StandardError)

    pages_dir_empty
  end

  it 'zip file contains all pages' do
    mock_translation_build
    allow(PageUtil).to receive(:delete_temp_pages)
    mock_s3(double(upload_file: true))

    push

    zip = Zip::File.open('pages/version_1.zip')
    expect(zip.get_entry('790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml')).to_not be_nil
    expect(zip.get_entry('5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml')).to_not be_nil
    delete_pages_dir
  end

  it 'zip file contains manifest' do
    mock_translation_build
    allow(PageUtil).to receive(:delete_temp_pages)
    mock_s3(double(upload_file: true))

    push

    zip = Zip::File.open('pages/version_1.zip')
    expect(zip.get_entry(@translation.manifest_name)).to_not be_nil
    delete_pages_dir
  end

  it 'zip file contains all attachments' do
    mock_translation_build
    allow(PageUtil).to receive(:delete_temp_pages)
    mock_s3(double(upload_file: true))

    push

    zip = Zip::File.open('pages/version_1.zip')
    expect(zip.get_entry('073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd')).to_not be_nil
    delete_pages_dir
  end

  it 'builds a manifest with names of all pages' do
    mock_translation_build
    mock_s3(double(upload_file: true))
    allow(PageUtil).to receive(:delete_temp_pages)

    push

    manifest = Nokogiri::XML(File.open("pages/#{@translation.manifest_name}")) do |config|
      config.options = Nokogiri::XML::ParseOptions::STRICT
    end
    expect(manifest.to_s).to eq('<?xml version="1.0"?>
<manifest>
  <pages>
    <page filename="13_FinalPage.xml" src="790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml"/>
    <page filename="04_ThirdPoint.xml" src="5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml"/>
  </pages>
  <resources>
    <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd"/>
  </resources>
</manifest>
')
    delete_pages_dir
  end

  it 'always uses strict mode' do
    mock_s3(double(upload_file: true))
    allow(@translation).to(
      receive(:build_translated_page).with(any_args, true)
        .and_return('this is a translated page', 'here is another translated page')
    )

    push
  end

  private

  def delete_pages_dir
    allow(PageUtil).to receive(:delete_temp_pages).and_call_original
    PageUtil.delete_temp_pages
  end

  def pages_dir_empty
    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  def mock_s3(object)
    bucket = double(object: object)
    s3 = double(bucket: bucket)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)
  end

  def mock_onesky
    onesky_project_id = Resource.find(godtools::ID).onesky_project_id
    allow(RestClient).to receive(:get)
      .with("https://platform.api.onesky.io/1/projects/#{onesky_project_id}/translations", any_args)
      .and_return('{ "1":"value" }')
  end

  def mock_translation_build
    allow(@translation).to(
      receive(:build_translated_page)
        .and_return('this is a translated page', 'here is another translated page')
    )
  end

  def push
    s3_util = S3Util.new(@translation)
    s3_util.push_translation
  end
end
