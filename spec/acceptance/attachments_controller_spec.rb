# frozen_string_literal: true

require 'acceptance_helper'

resource 'Attachments' do
  let(:test_file) { Rack::Test::UploadedFile.new('public/wall.jpg', 'image/png') }

  post 'attachments/' do
    it 'does not allow unauthorized requests', document: false do
      header 'Authorization', nil

      do_request file: test_file, key: 'test_image', multipart: true, resource_id: 1

      expect(status).to be(401)
    end

    it 'create an Attachment' do
      header 'Authorization', AuthToken.create(access_code: AccessCode.find(1)).token

      do_request file: test_file, key: 'test_image', multipart: true, resource_id: 1

      expect(status).to be(201)
    end
  end
end
