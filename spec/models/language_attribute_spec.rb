require "rails_helper"

RSpec.describe LanguageAttribute, type: :model do
  let(:resource) { Resource.first }
  let(:language) { Language.first }
  let(:language2) { Language.second }

  let!(:attribute) { FactoryBot.create(:language_attribute, language: language, resource: resource, key: "enable_tips", value: "true") }

  it "resource/language/key combination must be unique and is not case sensitive" do
    attr = described_class.create(resource_id: resource.id, language_id: language.id, key: "enABle_tips", value: "false")

    expect(attr.errors[:resource]).to include "has already been taken"
  end

  it "key can be reused by multiple languages for a resource" do
    attr = described_class.create(resource_id: resource.id, language_id: language2.id, key: "enable_tips", value: "false")

    expect(attr).to be_valid
  end
end
