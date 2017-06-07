
# frozen_string_literal: true

require 'rails_helper'
require 'validates_email_format_of/rspec_matcher'

describe FollowUp do
  let(:destination) do
    Destination.new(id: 123,
                    route_id: '12',
                    url: 'myapi.org',
                    access_key_id: '123456',
                    access_key_secret: 'hello, world!')
  end
  let(:email) { 'bob@test.org' }
  let(:language) { Language.find(2) }
  let(:language_id) { 3 }
  let(:first_name) { 'Bob' }
  let(:last_name) { 'Test' }
  let(:full_name) { "#{first_name} #{last_name}" }

  before do
    allow(Destination).to receive(:find).with(123).and_return(destination)
  end

  it 'validates email address' do
    result = described_class.new('myemail', language.id, destination.id, full_name)

    expect(result).not_to be_valid
    expect(result.errors[:email]).to include('Invalid email address')
  end

  context 'sends correct values to api' do
    let(:follow_up) { described_class.new(email, language.id, destination.id, full_name) }

    before do
      allow(RestClient).to receive(:post).and_return(double.as_null_object)
    end

    it 'url' do
      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(destination.url, anything, anything)
    end

    it 'body' do
      expected = "subscriber[route_id]=#{destination.route_id}&subscriber[language_code]=#{language.code}"\
                 "&subscriber[first_name]=#{first_name}&subscriber[last_name]=#{last_name}&subscriber[email]=#{email}"

      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(any_string, expected, anything)
    end

    it 'access key id' do
      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(any_string,
                                                      anything,
                                                      hash_including('Access-Id': destination.access_key_id))
    end

    it 'access key secret' do
      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(any_string,
                                                      anything,
                                                      hash_including('Access-Secret': destination.access_key_secret))
    end
  end
end