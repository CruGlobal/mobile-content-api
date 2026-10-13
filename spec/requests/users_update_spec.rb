# frozen_string_literal: true

require "rails_helper"

describe "Users update", type: :request do
  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:editor) { FactoryBot.create(:user, admin: false) }
  let(:subject_user) { FactoryBot.create(:user, admin: false, first_name: "Before", last_name: "Change") }

  def headers_for(user)
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  def body(attributes)
    {data: {attributes: attributes}}.to_json
  end

  describe "authorization of the subject" do
    it "lets an admin update another user" do
      patch "/users/#{subject_user.id}",
        params: body("given-name" => "After"), headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(subject_user.reload.first_name).to eq("After")
    end

    it "refuses a non-admin acting on someone else" do
      patch "/users/#{subject_user.id}",
        params: body("given-name" => "After"), headers: headers_for(editor)

      expect(response).to have_http_status(:forbidden)
      expect(subject_user.reload.first_name).to eq("Before")
    end

    it "lets an admin delete another user" do
      target = subject_user

      delete "/users/#{target.id}", headers: headers_for(admin)

      expect(response).to have_http_status(:no_content)
      expect(User.exists?(target.id)).to be(false)
    end
  end

  describe "writable columns" do
    it "writes the real columns, not just the attr-* bag" do
      patch "/users/#{subject_user.id}",
        params: body(
          "given-name" => "New",
          "family-name" => "Name",
          "email" => "new@example.com",
          "attr-something" => "kept"
        ),
        headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      subject_user.reload
      expect(subject_user.first_name).to eq("New")
      expect(subject_user.last_name).to eq("Name")
      expect(subject_user.email).to eq("new@example.com")
      expect(subject_user.user_attributes.find_by(key: "something").value).to eq("kept")
    end

    it "leaves omitted columns alone rather than nulling them" do
      patch "/users/#{subject_user.id}",
        params: body("given-name" => "OnlyFirst"), headers: headers_for(admin)

      expect(subject_user.reload.last_name).to eq("Change")
    end

    it "returns 422 rather than 500 when the record is invalid" do
      patch "/users/#{subject_user.id}",
        params: body("email" => ""), headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "the admin flag" do
    it "lets an admin grant admin to someone else" do
      patch "/users/#{subject_user.id}",
        params: body("admin" => true), headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(subject_user.reload.admin).to be(true)
    end

    # A non-admin may PATCH their own record, so the flag must not be writable
    # by them or self-promotion is one request away.
    it "ignores a non-admin trying to promote themselves" do
      patch "/users/#{editor.id}",
        params: body("given-name" => "Sneaky", "admin" => true),
        headers: headers_for(editor)

      expect(response).to have_http_status(:ok)
      editor.reload
      expect(editor.first_name).to eq("Sneaky")
      expect(editor.admin).to be(false)
    end
  end
end
