# frozen_string_literal: true

require 'rails_helper'
require 's3_util'

describe S3Util do
  let(:godtools) { TestConstants::GodTools }

  before(:each) do
    mock_s3
    mock_onesky
    push
  end

  it 'deletes temp files' do
    push

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  it 'deletes zip file' do
    push
    expect(File).to_not exist('version_1.zip')
  end

  private

  def mock_s3
    object = double(upload_file: true)
    bucket = double(object: object)
    s3 = double(bucket: bucket)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)
  end

  def mock_onesky
    onesky_project_id = Resource.find(godtools::ID).onesky_project_id
    allow(RestClient).to receive(:get)
      .with("https://platform.api.onesky.io/1/projects/#{onesky_project_id}/translations", any_args)
      .and_return('{ "this is some json":"value" }')
  end

  def push
    translation = Translation.find(godtools::Translations::English::ID)
    s3helper = S3Util.new(translation)
    s3helper.push_translation
  end
end
