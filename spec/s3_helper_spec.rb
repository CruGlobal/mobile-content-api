# frozen_string_literal: true

require 'rails_helper'
require 's3_helper'

describe S3Helper do
  it 'deletes temp files' do
    push

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir.empty?).to be(true)
  end

  it 'deletes zip file' do
    push
    expect(File.exist?('version_1.zip')).to be(false)
  end

  private def push
    object = double(upload_file: true)
    bucket = double(object: object)
    s3 = double(bucket: bucket)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)

    translation = Translation.find(1)
    s3helper = S3Helper.new(translation)
    s3helper.push_translation
  end
end
