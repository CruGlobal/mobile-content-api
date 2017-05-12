# frozen_string_literal: true

require 'rails_helper'

describe AuthToken do
  let(:access_code) { AccessCode.find(TestConstants::AccessCodes::ID) }

  it 'generates a value for the token' do
    result = AuthToken.create!(access_code: access_code)
    expect(result).to_not be_nil
  end

  it 'sets expiration to 24 hours after creation' do
    time = DateTime.current
    allow(DateTime).to receive(:now).and_return(time)

    result = AuthToken.create!(access_code: access_code)

    expect(result.expiration).to eq(time + 24.hours)
  end
end
