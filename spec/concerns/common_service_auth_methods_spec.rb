# spec/models/concerns/my_concern_spec.rb
require 'rails_helper'

describe CommonServiceAuthUserMethods do

  describe '#new_user' do
    let(:primary_key) { "facebook_user_id" }
    let(:id) { 1234567890 }
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
        ::CommonServiceAuthUserMethods.new_user(primary_key, id, user_atts)
      end.to change(User, :count).by(1)

      user = User.last
      expect(user.facebook_user_id.to_i).to eql id
      expect(user.first_name).to eql first_name
      expect(user.last_name).to eql last_name
      expect(user.email).to eql email
    end
  end
end
