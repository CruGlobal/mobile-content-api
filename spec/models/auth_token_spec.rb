# frozen_string_literal: true

require 'rails_helper'

describe AuthToken do
  it 'creates a token if access code is valid' do
    result = AuthToken.create_from_access_code!(AccessCode.find_by(code: 123_456))
    expect(result).to be(:created)
  end

  it 'generates a value for the token' do
    result = AuthToken.create(access_code: AccessCode.find(1))
    expect(result).to_not be(nil)
  end

  it 'returns bad request a token if access code is invalid' do
    result = AuthToken.create_from_access_code!(AccessCode.find_by(code: 023_456))
    expect(result).to be(:bad_request)
  end
end
