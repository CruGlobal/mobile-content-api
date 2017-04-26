# frozen_string_literal: true

require 'rails_helper'
require 's3_util'

describe S3Util do
  let(:godtools) { TestConstants::GodTools }

  before(:each) do
    mock_onesky
    push
  end

  it 'deletes temp files after successful request' do
    mock_s3(double(upload_file: true))

    push

    pages_dir_empty
  end

  it 'deletes zip file after successful request' do
    mock_s3(double(upload_file: true))

    push

    expect(File).to_not exist('version_1.zip')
  end

  it 'deletes temp files and zip file if error is raised' do
    object = double
    allow(object).to receive(:upload_file).and_raise(StandardError)
    mock_s3(object)

    expect { push }.to raise_error(StandardError)

    pages_dir_empty
    expect(File).to_not exist('version_1.zip')
  end

  private

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

  def push
    translation = Translation.find(godtools::Translations::English::ID)
    allow(translation).to receive(:build_translated_page).and_return('this is a translated page')
    s3_util = S3Util.new(translation)
    s3_util.push_translation
  end
end
