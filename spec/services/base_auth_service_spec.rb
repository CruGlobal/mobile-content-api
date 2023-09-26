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

  describe "#new_user" do
    let(:primary_key) { "facebook_user_id" }
    let(:id) { "1234567890" }
    let(:first_name) { "Marx" }
    let(:last_name) { "Powel" }
    let(:email) { "test@email.com" }

    let(:user_atts) do
      {
        first_name: first_name,
        last_name: last_name,
        email: email
      }
    end

    it "create a new persisted user" do
      expect do
        BaseAuthService.new_user(primary_key, id, user_atts)
      end.to change(User, :count).by(1)

      user = User.last
      expect(user.facebook_user_id).to eql id
      expect(user.first_name).to eql first_name
      expect(user.last_name).to eql last_name
      expect(user.email).to eql email
    end
  end
end
