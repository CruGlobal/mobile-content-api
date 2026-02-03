# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceDefaultOrder, type: :model do
  let(:resource) { Resource.first }
  let(:language) { Language.find_or_create_by!(code: "en", name: "English") }
  let(:other_language) { Language.find_or_create_by!(code: "fr", name: "French") }
  subject(:resource_default_order) { FactoryBot.build(:resource_default_order, resource: resource, language: language) }

  describe "validations" do
    it { is_expected.to be_valid }

    context "uniqueness validation" do
      before { FactoryBot.create(:resource_default_order, resource: resource, language: language, position: 1) }

      it "validates uniqueness of default order per language" do
        duplicate = FactoryBot.build(:resource_default_order, resource: resource, language: language, position: 1)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:resource_id]).to include("should have only one ResourceDefaultOrder per language")
      end

      it "allows same position for different language" do
        different_lang = FactoryBot.build(:resource_default_order, resource: resource, language: other_language,
          position: 1)
        expect(different_lang).to be_valid
      end
    end
  end
end
