# frozen_string_literal: true

require 'rails_helper'

describe AuthToken do
  it 'generates a value for the token' do
    result = AuthToken.create(access_code: AccessCode.find(TestConstants::AccessCodes::ID))
    expect(result).to_not be_nil
  end
end
