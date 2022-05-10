# frozen_string_literal: true

require "rails_helper"
require "page_client"

describe Resource do
  let(:resource) { described_class.find(2) }

  context "create draft" do
    let(:language) { Language.find(3) }

    context "new resource/language combination" do
      it "pushes to OneSky" do
        allow(PageClient).to(receive(:new).with(resource, language.code)
                                 .and_return(instance_double(PageClient, push_new_onesky_translation: :created)))

        resource.create_draft(language.id)
      end

      it "adds a new draft" do
        allow(Translation).to receive(:create!)
        allow(PageClient).to receive(:new).with(resource, language.code).and_return(double.as_null_object)

        resource.create_draft(language.id)

        expect(Translation).to have_received(:create!).with(resource: resource, language: language)
      end
    end

    context "existing resource/language combination" do
      it "adds a new version" do
        translation = instance_double(Translation, create_new_version: nil)
        allow(Translation).to receive(:latest_translation).with(resource.id, language.id).and_return(translation)

        resource.create_draft(language.id)

        expect(translation).to have_received(:create_new_version)
      end
    end
  end

  context "returns latest published translation for each language" do
    let(:latest_translations) { resource.latest_translations }

    it "resource has 2 translations" do
      expect(latest_translations.count).to be(2)
    end

    it "returns highest version for each language" do
      expect(latest_translations[0][:id]).to eq(5)
      expect(latest_translations[1][:id]).to eq(8)
    end
  end

  context "returns latest translation (published or not) for each language" do
    it "resource has 2 translations" do
      expect(resource.latest_drafts_translations.count).to be(2)
    end

    it "returns highest version for each language" do
      expect(resource.latest_drafts_translations[0][:id]).to eq(6)
      expect(resource.latest_drafts_translations[1][:id]).to eq(8)
    end

    it "is ordered by language" do
      resource_kgp = described_class.find(1)

      expect(resource_kgp.latest_drafts_translations[0].language).to eq(Language.find(4))
    end
  end

  it "validates manifest if present" do
    attributes = {name: "test", abbreviation: "t", system_id: 1, resource_type_id: 1, manifest: "<xml>bad xml</xml>"}

    result = described_class.create(attributes)

    expect(result.errors["manifest"])
      .to include("1:0: ERROR: Element 'xml': No matching global declaration available for the validation root.")
  end

  context "with metatools" do
    let(:metatool_resource_type) { ResourceType.find_by(name: "metatool") }
    let(:article_resource_type) { ResourceType.find_by(name: "article") }
    let!(:metatool) { FactoryBot.create(:resource, system_id: 1, resource_type: metatool_resource_type) }
    let!(:article) { FactoryBot.create(:resource, system_id: 1, resource_type: article_resource_type) }

    it "validates metatool exists" do
      attributes = {name: "test", abbreviation: "1", system_id: 1, resource_type_id: article_resource_type.id, metatool_id: 100}

      expect do
        described_class.create(attributes)
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "validates metatool is a metatool" do
      attributes = {name: "test", abbreviation: "1", system_id: 1, resource_type_id: article_resource_type.id, metatool_id: article.id}

      result = described_class.create(attributes)
      expect(result.errors["metatool"]).to include("is not a metatool")
    end

    it "creates a new resource with valid metatool reference" do
      attributes = {name: "test", abbreviation: "1", system_id: 1, resource_type_id: article_resource_type.id, metatool_id: metatool.id}

      expect do
        result = described_class.create!(attributes)
        expect(result.metatool).to eq(metatool)
      end.to change(Resource, :count).by(1)
    end
  end
end
