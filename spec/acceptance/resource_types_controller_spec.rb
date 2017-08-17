# frozen_string_literal: true

resource 'ResourceTypes' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }

  get 'resource_types/' do
    it 'get all resource types' do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)['data'].count).to be(2)
    end
  end
end
