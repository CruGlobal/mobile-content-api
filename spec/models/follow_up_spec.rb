
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
    result = described_class
             .create(email: 'myemail', language_id: language.id, destination_id: destination.id, name: full_name)

    expect(result.errors[:email]).to include('Invalid email address')
  end

  it 'returns remote response code if request failed' do
    code = 404
    follow_up = described_class.create(valid_attrs)
    mock_rest_client(code)

    expect { follow_up.send_to_api }
      .to raise_error("Received response code: #{code} from destination: #{destination.id}")
  end

  it 'ensures record is saved before sending to destination' do
    mock_rest_client(201)
    follow_up = described_class.new(valid_attrs)
    allow(follow_up).to receive(:save!)

    follow_up.send_to_api

    expect(follow_up).to have_received(:save!)
  end

  context 'sends correct values to api' do
    let(:follow_up) { described_class.create(valid_attrs) }

    before do
      mock_rest_client(201)
    end

    it 'url' do
      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(destination.url, anything, anything)
    end

    it 'body' do
      expected = "subscriber[route_id]=#{destination.route_id}&subscriber[language_code]=#{language.code}"\
                 "&subscriber[email]=#{email}&subscriber[first_name]=#{first_name}&subscriber[last_name]=#{last_name}"\
                 "&access_id=#{destination.access_key_id}&access_secret=#{destination.access_key_secret}"

      follow_up.send_to_api

      expect(RestClient).to have_received(:post).with(any_string, expected, anything)
    end
  end

  private

  def valid_attrs
    { email: email, language_id: language.id, destination_id: destination.id, name: full_name }
  end

  def mock_rest_client(code)
    allow(RestClient).to(
      receive(:post).and_return(double.as_null_object).and_return(instance_double(RestClient::Response, code: code))
    )
  end
end
