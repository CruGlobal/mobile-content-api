# frozen_string_literal: true

require 'rails_helper'
require 's3_helper'

describe S3Helper do
  it 'deletes temp files' do
    push

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  it 'deletes zip file' do
    push
    expect(File).to_not exist('version_1.zip')
  end

  private def push
    object = double(upload_file: true)
    bucket = double(object: object)
    s3 = double(bucket: bucket)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)

    translation = Translation.find(TestConstants::GodTools::Translations::English::ID)
    s3helper = S3Helper.new(translation)
    s3helper.push_translation
  end
end
