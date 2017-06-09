
# frozen_string_literal: true

require 'rails_helper'
require 'validates_email_format_of/rspec_matcher'

describe FollowUp do
  let(:destination) { Destination.find(1) }
  let(:email) { 'bob@test.org' }
  let(:language) { Language.find(2) }
  let(:language_id) { 3 }
  let(:first_name) { 'Bob' }
  let(:last_name) { 'Test' }
  let(:full_name) { "#{first_name} #{last_name}" }

  it 'validates email address' do
    result = described_class.new('myemail', language.id, destination.id, full_name)

    expect(result).not_to be_valid
    expect(result.errors[:email]).to include('Invalid email address')
  end

  it 'returns remote response code if request failed' do
    code = 404
    follow_up = described_class.new(email, language.id, destination.id, full_name)
    mock_rest_client(code)

    expect { follow_up.send_to_api }
      .to raise_error("Received response code: #{code} from destination: #{destination.id}")
  end

  it 'does not send if record is invalid' do
    follow_up = described_class.new(nil, language.id, destination.id, full_name)

    expect { follow_up.send_to_api }.to raise_error("Email can't be blank, Email Invalid email address")
  end

  context 'sends correct values to api' do
    let(:follow_up) { described_class.new(email, language.id, destination.id, full_name) }

    before do
      mock_rest_client(201)
    end

    it 'url' do
      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(destination.url, anything, anything)
    end

    it 'body' do
      expected = "subscriber[route_id]=#{destination.route_id}&subscriber[language_code]=#{language.code}"\
                 "&subscriber[email]=#{email}&subscriber[first_name]=#{first_name}&subscriber[last_name]=#{last_name}"

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

  private

  def mock_rest_client(code)
    allow(RestClient).to(
      receive(:post).and_return(double.as_null_object).and_return(instance_double(RestClient::Response, code: code))
    )
  end
end
