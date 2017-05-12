# frozen_string_literal: true

require 'rails_helper'

describe Attachment do
  let(:test_file) { Rack::Test::UploadedFile.new('public/wall.jpg', 'image/png') }

  before(:each) do
    allow_any_instance_of(Paperclip::Attachment).to receive(:save).and_return(true)
  end

  it 'is not zipped unless specified' do
    result = Attachment.create(resource_id: 1, file: test_file)

    expect(result).to be_valid
    expect(result.is_zipped).to be_falsey
  end
end
