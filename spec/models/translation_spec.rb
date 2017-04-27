# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  let(:translations) { TestConstants::GodTools::Translations }

  it 'downloads translated phrases from OneSky' do
    mock_onesky('13_FinalPage.xml', '{ "1":"This is a German phrase", "2":"another phrase in German" }')
    translation = Translation.find(translations::German1::ID)

    result = translation.download_translated_phrases('13_FinalPage.xml')

    values = JSON.parse(result)
    expect(values['1']).to eq('This is a German phrase')
    expect(values['2']).to eq('another phrase in German')
  end

  it 'builds a translated page from resource page' do
    mock_onesky('13_FinalPage.xml', '{ "1":"This is a German phrase", "2":"another phrase in German" }')
    translation = Translation.find(translations::German1::ID)

    result = translation.build_translated_page(1)

    expect(result.include?('base_xml_element')).to be_truthy
    expect(result.include?('<content:text i18n-id="1">This is a German phrase</content:text>')).to be_truthy
    expect(result.include?('<content:text i18n-id="2">another phrase in German</content:text>')).to be_truthy
  end

  it 'builds a translated page from custom page' do
    mock_onesky('13_FinalPage.xml', '{ "1":"This is a German phrase", "2":"another phrase in German" }')
    translation = Translation.find(translations::German2::ID)

    result = translation.build_translated_page(1)

    expect(result.include?('custom_xml_element')).to be_truthy
    expect(result.include?('<content:text i18n-id="1">This is a German phrase</content:text>')).to be_truthy
    expect(result.include?('<content:text i18n-id="2">another phrase in German</content:text>')).to be_truthy
  end

  it 'error is raised if translated phrase not found' do
    mock_onesky('13_FinalPage.xml', '{ "1":"This is a German phrase" }')
    translation = Translation.find(translations::German2::ID)

    expect { translation.build_translated_page(1) }.to raise_error('Translated phrase not found.')
  end

  it 'increments version by one' do
    translation = Translation.find(translations::English::ID)
    new_translation = translation.create_new_version

    expect(new_translation.version).to be(2)
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
