# spec/models/concerns/common_service_auth_user_methods_spec.rb
require "rails_helper"

describe CommonServiceAuthUserMethods do
  describe  "#user_not_found" do

   context "when user is not found" do
    context "and :create_user passed as 'false'" do
      let(:create_user) { false }
      let(:users) { [] }

      it "return true" do
        expect(::CommonServiceAuthUserMethods.user_not_found(create_user, users)).to eql true
      end
    end

    context "and :create_user passed as 'true'" do
      let(:create_user) { true }
      let(:users) { [] }

      it "return false" do
        expect(::CommonServiceAuthUserMethods.user_not_found(create_user, users)).to eql false
      end
    end
   end

   context "when user is found" do
     let(:user) { FactoryBot.create(:user) }
     let(:users) { [user] }

     context "and :create_user passed as 'true'" do
       let(:create_user) { true }

       it "return false" do
         expect(::CommonServiceAuthUserMethods.user_not_found(create_user, users)).to eql false
       end
     end

     context "and :create_user passed as 'nil'" do
       let(:create_user) { nil }

       it "return false" do
         expect(::CommonServiceAuthUserMethods.user_not_found(create_user, users)).to eql false
       end
     end
   end
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
        ::CommonServiceAuthUserMethods.new_user(primary_key, id, user_atts)
      end.to change(User, :count).by(1)

      user = User.last
      expect(user.facebook_user_id).to eql id
      expect(user.first_name).to eql first_name
      expect(user.last_name).to eql last_name
      expect(user.email).to eql email
    end
  end
end
