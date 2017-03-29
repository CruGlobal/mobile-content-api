# frozen_string_literal: true

require 'rails_helper'

describe AuthToken do
  it 'creates a token if access code is valid' do
    result = AuthToken.create_from_access_code(AccessCode.find_by(code: 123_456))
    assert(result == :created)
  end

  it 'returns bad request a token if access code is invalid' do
    result = AuthToken.create_from_access_code(AccessCode.find_by(code: 023_456))
    assert(result == :bad_request)
  end
end
