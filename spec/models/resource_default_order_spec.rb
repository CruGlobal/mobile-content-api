require 'rails_helper'

RSpec.describe ResourceDefaultOrder, type: :model do
  let(:resource) { Resource.first || FactoryBot.create(:resource) }
  subject(:resource_default_order) { FactoryBot.build(:resource_default_order, resource: resource) }

  describe "validations" do
    it { is_expected.to be_valid }

    context "uniqueness validation" do
      before { FactoryBot.create(:resource_default_order, resource: resource, lang: "en", position: 1) }

      it "validates uniqueness of position scoped to lang" do
        duplicate = FactoryBot.build(:resource_default_order, resource: resource, lang: "en", position: 1)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:resource_id]).to include("should have only one resource per language")
      end

      it "allows same position for different language" do
        different_lang = FactoryBot.build(:resource_default_order, resource: resource, lang: "es", position: 1)
        expect(different_lang).to be_valid
      end
    end
  end

  describe "callbacks" do
    context "before_save" do
      it "downcases lang" do
        resource_default_order.lang = "EN"
        resource_default_order.save
        expect(resource_default_order.lang).to eq("en")
      end
    end
  end
end
