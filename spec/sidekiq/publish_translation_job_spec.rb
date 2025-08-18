require "rails_helper"
RSpec.describe PublishTranslationJob, type: :job do
  let!(:translation) { Resource.first.latest_translations.first }
  let!(:package) { Package.new(translation) }

  before do
    translation.update(is_published: false)
  end

  it "captures errors into publishing_errors" do
    mock_crowdin
    allow(Package).to receive(:new).and_return(package)
    PublishTranslationJob.new.perform(translation.id)
    expect(translation.reload.is_published).to be false
    expect(translation.publishing_errors).to eq("Translated phrase not found: ID: 89a09d72-114f-4d89-a72c-ca204c796fd9, base text: Knowing God Personally")
  end

  it "sets the is_published to true" do
    allow(Translation).to receive(:find).with(translation.id).and_return(translation)
    allow(Package).to receive(:new).and_return(package)
    allow(package).to receive(:build_zip)
    allow(package).to receive(:upload)
    allow(translation).to receive(:download_translated_phrases).and_return({})
    allow(translation).to receive(:name_desc_crowdin).with({})
    allow(translation).to receive(:create_translated_attributes).with({})

    PublishTranslationJob.new.perform(translation.id)
    expect(translation.reload.is_published).to be true
  end
end
