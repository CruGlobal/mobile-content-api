# frozen_string_literal: true

require 'rails_helper'

describe Attachment do
  let(:test_file) { Rack::Test::UploadedFile.new('public/wall.jpg', 'image/png') }

  before(:each) do
    allow_any_instance_of(Paperclip::Attachment).to receive(:save).and_return(true)
  end

  it 'may not have the same key and resource id as an Attribute' do
    expect { Attachment.create!(key: 'banner_image', file: test_file, resource_id: 1) }
      .to(raise_error('Key is currently used by an Attribute.'))
  end

  it 'may not duplicate key and resource id and is not case sensitive' do
    result = Attachment.create(key: 'banner_IMAge', file: test_file, resource_id: 2)

    expect(result).to_not be_valid
    expect(result.errors[:resource]).to include 'has already been taken'
  end
end
