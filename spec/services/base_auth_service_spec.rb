require "rails_helper"

RSpec.describe BaseAuthService do
  it "requires implementation of decode_token" do
    expect do
      BaseAuthService.send(:decode_token, nil)
    end.to raise_exception(StandardError, "extending class should implement decode_token(access_token)")
  end
  it "requires implementation of expected_fields" do
    expect do
      BaseAuthService.send(:expected_fields)
    end.to raise_exception(StandardError, "extending class should implement expected_fields (returning array of strings)")
  end
  it "requires implementation of remote_user_id" do
    expect do
      BaseAuthService.send(:remote_user_id, nil)
    end.to raise_exception(StandardError, "extending class should implement remote_user_id(decoded_token)")
  end
  it "requires implementation of decode_token" do
    expect do
      BaseAuthService.send(:validate_token!, nil, nil)
    end.to raise_exception(StandardError, "extending class should implement validate_token!(access_token, decoded_token)")
  end
  it "requires implementation of decode_token" do
    expect do
      BaseAuthService.send(:extract_user_atts, nil, nil)
    end.to raise_exception(StandardError, "extending class should implement extract_user_atts(access_token, decoded_token)")
  end
end
