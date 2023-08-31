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


  describe "#existent_user" do
    context "when user already exists" do
      let(:create_user) { false }
      let(:user) { FactoryBot.create(:user) }
      let(:users) { [user] }

      it "returns an user object" do
        expect(BaseAuthService.existent_user(create_user, users)).to eql users.first
      end
    end

    context "when user does not already exists" do
      let(:create_user) { false }
      let(:users) { [] }

      it "returns nil" do
        expect(BaseAuthService.existent_user(create_user, users)).to eql nil
      end
    end
  end

  describe "#user_already_exist" do
    context "when user is found" do
      let(:user) { FactoryBot.create(:user) }
      let(:users) { [user] }

      context "and :create_user passed as 'false'" do
        let(:create_user) { false }

        it "return false" do
          expect(BaseAuthService.user_already_exist(create_user, users)).to eql false
        end
      end

      context "and :create_user passed as 'true'" do
        let(:create_user) { true }

        it "return true" do
          expect(BaseAuthService.user_already_exist(create_user, users)).to eql true
        end
      end
    end

    context "when user is not found" do
      let(:users) { [] }

      context "and :create_user passed as 'false'" do
        let(:create_user) { false }

        it "return false" do
          expect(BaseAuthService.user_already_exist(create_user, users)).to eql false
        end
      end

      context "and :create_user passed as 'true'" do
        let(:create_user) { true }

        it "return true" do
          expect(BaseAuthService.user_already_exist(create_user, users)).to eql false
        end
      end
    end
  end

  describe "#user_not_found" do
    context "when user is not found" do
      context "and :create_user passed as 'false'" do
        let(:create_user) { false }
        let(:users) { [] }

        it "return true" do
          expect(BaseAuthService.user_not_found(create_user, users)).to eql true
        end
      end

      context "and :create_user passed as 'true'" do
        let(:create_user) { true }
        let(:users) { [] }

        it "return false" do
          expect(BaseAuthService.user_not_found(create_user, users)).to eql false
        end
      end
    end

    context "when user is found" do
      let(:user) { FactoryBot.create(:user) }
      let(:users) { [user] }

      context "and :create_user passed as 'true'" do
        let(:create_user) { true }

        it "return false" do
          expect(BaseAuthService.user_not_found(create_user, users)).to eql false
        end
      end

      context "and :create_user passed as 'nil'" do
        let(:create_user) { nil }

        it "return false" do
          expect(BaseAuthService.user_not_found(create_user, users)).to eql false
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
