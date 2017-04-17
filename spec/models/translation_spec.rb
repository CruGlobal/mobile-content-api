# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  let(:translations) { TestConstants::GodTools::Translations }

  it 'downloads translated page from OneSky' do
    mock_onesky('13_FinalPage.xml', '{ "3":"This is a German phrase" }')
    translation = Translation.find(translations::German1::ID)

    result = translation.download_translated_page('13_FinalPage.xml')

    values = JSON.parse(result)
    expect(values['3']).to eq('This is a German phrase')
  end

  it 'increments version by one' do
    translation = Translation.find(translations::English::ID)
    new_translation = translation.create_new_version

    expect(new_translation.version).to be(2)
  end

  it 'replaces original pages with custom pages' do
    german_kgp = Translation.find(translations::German2::ID)
    pages = german_kgp.translated_pages

    expect(pages[0].structure).to eq('<custom>This is some custom xml for one translation</custom>')
    expect(pages[1].structure).to eq('<note><to>Tove</to><from>Jani</from><heading>Reminder</heading>'\
                                 '<body>Dont forget me this weekend!</body></note>')
  end

  context 'latest translation' do
    it 'returns latest version for resource/language combination' do
      translation = Translation.latest_translation(TestConstants::GodTools::ID, TestConstants::Languages::German::ID)
      expect(translation.version).to be(2)
    end

    it 'returns nil for resource/language combination that does not exist' do
      translation = Translation.latest_translation(TestConstants::GodTools::ID, TestConstants::Languages::Slovak::ID)
      expect(translation).to be_nil
    end
  end

  it 'returns the S3 URI as bucket/system name/resource abbreviation/language abbreviation' do
    bucket = 'test_bucket'
    stub_const('ENV', 'MOBILE_CONTENT_API_BUCKET' => bucket)

    uri = Translation.find(translations::English::ID).s3_uri
    expect(uri).to eq("https://s3.amazonaws.com/#{bucket}/GodTools/kgp/en/version_1.zip")
  end

  it 'raises an error if deletion of a translation is attempted' do
    translation = Translation.find(translations::English::ID)

    expect { translation.destroy! }.to raise_error(Error::TranslationError, 'Cannot delete published drafts.')
  end

  context 'is_published set to true' do
    let(:translation) { Translation.find(translations::German2::ID) }

    before(:each) do
      mock_onesky('name_description.xml', '{ "name":"kgp german", "description":"german description" }')
    end

    it 'uploads the translation to S3' do
      s3_util = double
      allow(S3Util).to receive(:new).and_return(s3_util)
      allow(s3_util).to receive(:push_translation)

      translation.update(is_published: true)
    end

    it 'downloads translated name and description' do
      s3_util = double.as_null_object
      allow(S3Util).to receive(:new).and_return(s3_util)

      translation.update(is_published: true)

      expect(translation.translated_name).to eq('kgp german')
      expect(translation.translated_description).to eq('german description')
    end
  end

  private

  def mock_onesky(filename, result)
    allow(RestClient).to receive(:get).with(any_args,
                                            hash_including(params: hash_including(source_file_name: filename)))
      .and_return(result)
  end
end
