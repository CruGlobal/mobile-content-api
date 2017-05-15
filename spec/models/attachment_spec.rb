# frozen_string_literal: true

require 'rails_helper'

describe Attachment do
  let(:test_file) { Rack::Test::UploadedFile.new('public/wall.jpg', 'image/png') }

  before(:each) do
    allow_any_instance_of(Paperclip::Attachment).to receive(:save).and_return(true)
  end

  it 'is not zipped unless specified' do
    result = Attachment.create(resource_id: 2, file: test_file)

    expect(result).to be_valid
    expect(result.is_zipped).to be_falsey
  end

  it 'cannot duplicate file name and resource' do
    result = Attachment.create(resource_id: 1, file: test_file)

    expect(result).to_not be_valid
  end

  it 'sha256 is saved on create' do
    result = Attachment.create(resource_id: 2, file: test_file)

    expect(result.sha256).to eq('073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd')
  end

  it 'sha256 is saved on update' do
    attachment = Attachment.find(1)
    attachment.update(resource_id: 2, file: Rack::Test::UploadedFile.new('public/beal.jpg', 'image/png'))

    expect(attachment.sha256).to eq('398ddaf37848344632c44bd9c057b7e092e19f93c825f6bc4737f885f517a2ce')
  end
end
