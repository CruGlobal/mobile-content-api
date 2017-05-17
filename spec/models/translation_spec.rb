# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  let(:translations) { TestConstants::GodTools::Translations }
  let(:page_name) { '13_FinalPage.xml' }
  let(:element_one_id) { 'f9894df9-df1d-4831-9782-345028c6c9a2' }
  let(:element_two_id) { '9deda19f-c3ee-42ed-a1eb-92423e543352' }
  let(:phrase_one) { 'This is a German phrase' }
  let(:phrase_two) { 'another phrase in German' }
  let(:phrases) { "{ \"#{element_one_id}\":\"#{phrase_one}\", \"#{element_two_id}\":\"#{phrase_two}\" }" }
  let(:phrase_one_element) { "<content:text i18n-id=\"#{element_one_id}\">#{phrase_one}</content:text>" }
  let(:phrase_two_element) { "<content:text i18n-id=\"#{element_two_id}\">#{phrase_two}</content:text>" }

  it 'downloads translated phrases from OneSky' do
    mock_onesky(page_name, phrases)
    translation = described_class.find(translations::German1::ID)

    result = translation.download_translated_phrases(page_name)

    expect(result[element_one_id]).to eq(phrase_one)
    expect(result[element_two_id]).to eq(phrase_two)
  end

  it 'PhraseNotFound error is raised if there is no phrases returned from OneSky' do
    mock_onesky(page_name, nil, 204)
    translation = described_class.find(translations::German1::ID)

    expect { translation.download_translated_phrases(page_name) }.to(
      raise_error(Error::PhraseNotFoundError, 'No translated phrases found for language locale: de')
    )
  end

  context 'builds a translated page from resource page' do
    let(:result) do
      translated_page(translations::German1::ID)
    end

    it 'includes base element' do
      expect(result.include?('base_xml_element')).to be_truthy
    end

    it 'includes translated phrases' do
      includes_translated_phrases
    end
  end

  context 'builds a translated page from custom page' do
    let(:result) do
      translated_page(translations::German2::ID)
    end

    it 'includes custom xml element' do
      expect(result.include?('custom_xml_element')).to be_truthy
    end
    it 'includes translated phrases' do
      includes_translated_phrases
    end
  end

  it 'error is raised if strict mode and translated phrase not found' do
    mock_onesky(page_name, "{ \"#{element_one_id}\":\"#{phrase_one}\" }")
    translation = described_class.find(translations::German2::ID)

    expect { translation.translated_page(1, true) }
      .to(raise_error(Error::PhraseNotFoundError,
                      "Translated phrase not found: ID: #{element_two_id}, base text: two un-translated phrase"))
  end

  it 'error not raised raised if not strict mode and translated phrase not found' do
    mock_onesky('13_FinalPage.xml', '{ "1":"This is a German phrase" }')
    translation = described_class.find(translations::German2::ID)

    translation.translated_page(1, false)
  end

  it 'uses existing translated pages for non-OneSky projects' do
    translation = described_class.find(10)

    result = translation.translated_page(3, false)

    expect(result).to eq('German translation of article Is There A God?')
  end

  it 'increments version by one' do
    translation = described_class.find(translations::English::ID)
    new_translation = translation.create_new_version

    expect(new_translation.version).to be(2)
  end

  context 'latest translation' do
    it 'returns latest version for resource/language combination' do
      translation = described_class.latest_translation(TestConstants::GodTools::ID,
                                                       TestConstants::Languages::German::ID)
      expect(translation.version).to be(2)
    end

    it 'returns nil for resource/language combination that does not exist' do
      translation = described_class.latest_translation(TestConstants::GodTools::ID,
                                                       TestConstants::Languages::Slovak::ID)
      expect(translation).to be_nil
    end
  end

  it 'returns the S3 URI as bucket/system name/resource abbreviation/language abbreviation' do
    bucket = 'test_bucket'
    stub_const('ENV', 'MOBILE_CONTENT_API_BUCKET' => bucket)

    uri = described_class.find(translations::English::ID).s3_uri
    expect(uri).to eq("https://s3.amazonaws.com/#{bucket}/GodTools/kgp/en/version_1.zip")
  end

  it 'raises an error if deletion of a translation is attempted' do
    translation = described_class.find(translations::English::ID)

    expect { translation.destroy! }.to raise_error(Error::TranslationError, 'Cannot delete published draft: 1')
  end

  context 'is_published set to true' do
    let(:translation) { described_class.find(translations::German2::ID) }

    before do
      mock_onesky('name_description.xml', '{ "name":"kgp german", "description":"german description" }')
    end

    it 'uploads the translation to S3' do
      s3_util = double
      allow(S3Util).to receive(:new).and_return(s3_util)
      allow(s3_util).to receive(:push_translation)

      translation.update(is_published: true)
    end

    context 'translated name and description' do
      before do
        s3_util = double.as_null_object
        allow(S3Util).to receive(:new).and_return(s3_util)
      end

      it 'updates from OneSky' do
        translation.update!(is_published: true)

        expect(translation.translated_name).to eq('kgp german')
        expect(translation.translated_description).to eq('german description')
      end

      it 'does not update from OneSky for projects not using it' do
        t = described_class.find(9)

        t.update!(id: 9, is_published: true)

        expect(t.translated_name).to be_nil
        expect(t.translated_description).to be_nil
      end
    end
  end

  private

  def translated_page(translation_id)
    mock_onesky(page_name, phrases)
    translation = described_class.find(translation_id)
    translation.translated_page(1, true)
  end

  def mock_onesky(filename, body, code = 200)
    allow(RestClient).to(
      receive(:get).with(any_args, hash_including(params: hash_including(source_file_name: filename)))
        .and_return(instance_double(RestClient::Response, body: body, code: code))
    )
  end

  def includes_translated_phrases
    expect(result.include?(phrase_one_element)).to be_truthy
    expect(result.include?(phrase_two_element)).to be_truthy
  end
end
