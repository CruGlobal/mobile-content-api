# frozen_string_literal: true

require 'acceptance_helper'

resource 'Attachments' do
  let(:test_file) { Rack::Test::UploadedFile.new('public/wall.jpg', 'image/png') }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }

  get 'attachments/:id/download' do
    let(:id) { 1 }

    it 'download an Attachment' do
      do_request

      expect(status).to be(302)
    end
  end

  post 'attachments/' do
    it 'does not allow unauthorized POSTs', document: false do
      header 'Authorization', nil

      do_request file: test_file, multipart: true, resource_id: 2

      expect(status).to be(401)
    end

    it 'create an Attachment' do
      header 'Authorization', :authorization

      do_request file: test_file, multipart: true, resource_id: 2

      expect(status).to be(204)
      expect(response_body).to be_empty
    end

    it 'sets location header', document: false do
      header 'Authorization', :authorization

      do_request file: test_file, multipart: true, resource_id: 2

      expect(response_headers['Location']).to match(%r{attachments\/\d+})
    end
  end

  put 'attachments/:id' do
    let(:id) { 1 }

    it 'does not allow unauthorized PUTs', document: false do
      header 'Authorization', nil

      do_request file: test_file, multipart: true, resource_id: 2

      expect(status).to be(401)
    end

    it 'update an Attachment' do
      header 'Authorization', :authorization

      do_request file: test_file, multipart: true, resource_id: 2

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end

  delete 'attachments/:id' do
    let(:id) { 1 }

    it 'does not allow unauthorized DELETEs' do
      header 'Authorization', nil

      do_request

      expect(status).to be(401)
    end

    it 'delete an Attachment' do
      header 'Authorization', :authorization

      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end
