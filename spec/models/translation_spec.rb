# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  let(:page_name) { '13_FinalPage.xml' }
  let(:element_one_id) { 'f9894df9-df1d-4831-9782-345028c6c9a2' }
  let(:element_two_id) { '9deda19f-c3ee-42ed-a1eb-92423e543352' }
  let(:phrase_one) { 'This is a German phrase' }
  let(:phrase_two) { 'another phrase in German' }
  let(:phrases) { "{ \"#{element_one_id}\":\"#{phrase_one}\", \"#{element_two_id}\":\"#{phrase_two}\" }" }
  let(:phrase_one_element) { "<content:text i18n-id=\"#{element_one_id}\">#{phrase_one}</content:text>" }
  let(:phrase_two_element) { "<content:text i18n-id=\"#{element_two_id}\">#{phrase_two}</content:text>" }

  context 'builds a translated page from resource page' do
    let(:result) do
      translated_page(1)
    end

    it 'builds from base XML' do
      expect(result.include?('form')).to be_truthy
    end

    it 'includes translated phrases' do
      includes_translated_phrases
    end
  end

  context 'builds a translated page from custom page' do
    let(:result) do
      translated_page(3)
    end

    it 'builds from custom XML' do
      expect(result.include?('form')).to be_falsey
    end
    it 'includes translated phrases' do
      includes_translated_phrases
    end
  end

  it 'error is raised if there is no phrases returned from OneSky' do
    mock_onesky(page_name, nil, 204)
    translation = described_class.find(2)

    expect { translation.translated_page(1, false) }.to(
      raise_error(Error::TextNotFoundError, 'No translated phrases found for this language.')
    )
  end

  it 'error is raised if strict mode and translated phrase not found' do
    mock_onesky(page_name, "{ \"#{element_one_id}\":\"#{phrase_one}\" }")
    translation = described_class.find(3)

    expect { translation.translated_page(1, true) }
      .to(raise_error(Error::TextNotFoundError,
                      "Translated phrase not found: ID: #{element_two_id}, base text: two un-translated phrase"))
  end

  it 'error not raised raised if not strict mode and translated phrase not found' do
    mock_onesky('13_FinalPage.xml', '{ "1":"This is a German phrase" }')
    translation = described_class.find(3)

    translation.translated_page(1, false)
  end

  it 'uses existing translated pages for non-OneSky projects' do
    translation = described_class.find(10)

    result = translation.translated_page(3, false)

    expect(result).to eq('German translation of article Is There A God?')
  end

  it 'error raised if translated page not found' do
    translation = described_class.find(9)

    expect { translation.translated_page(3, false) }.to(
      raise_error(Error::TextNotFoundError, 'Translated page not found for this language.')
    )
  end

  it 'is invalid if draft exists' do
    t = described_class.create(resource_id: 1, language_id: 2)

    expect(t).not_to be_valid
    expect(t.errors[:id]).to(
      include("Draft already exists for Resource ID: #{t.resource.id} and Language ID: #{t.language.id}")
    )
  end

  context 'latest translation' do
    it 'returns latest version for resource/language combination' do
      translation = described_class.latest_translation(1, 2)
      expect(translation.version).to be(2)
    end

    it 'returns nil for resource/language combination that does not exist' do
      translation = described_class.latest_translation(1, 3)
      expect(translation).to be_nil
    end
  end

  context 'redirect to S3' do
    let(:translation) { described_class.find(1) }
    let(:object) do
      object = instance_double(Aws::S3::Object)
      mock_s3(object, translation)
      object
    end

    it 'returns public url' do
      expected = 'my_object_url'
      allow(object).to receive(:exists?).and_return(true)
      allow(object).to receive(:public_url).and_return(expected)

      result = translation.s3_url

      expect(result).to eq(expected)
    end

    it 'raises an error if object does not exist' do
      allow(object).to receive(:exists?).and_return(false)

      expect { translation.s3_url }.to raise_error("Zip file not found in S3 for translation: #{translation.id}")
    end
  end

  it 'raises an error if deletion of a translation is attempted' do
    translation = described_class.find(1)

    expect { translation.destroy! }.to raise_error(Error::TranslationError, 'Cannot delete published draft: 1')
  end

  context 'is_published set to true' do
    let(:translation) { described_class.find(3) }

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
      let(:s3_util) { double.as_null_object }

      before do
        allow(S3Util).to receive(:new).and_return(s3_util)
      end

      it 'updates from OneSky' do
        translation.update!(is_published: true)

        expect(translation.translated_name).to eq('kgp german')
        expect(translation.translated_description).to eq('german description')
      end

      it 'translated name is updated prior to building zip' do # S3Util needs the translated name/description
        allow(translation).to receive(:translated_name=)

        translation.update!(is_published: true)

        expect(translation).to have_received(:translated_name=).ordered
        expect(s3_util).to have_received(:push_translation).ordered
      end

      it 'translated description is updated prior to building zip' do
        allow(translation).to receive(:translated_description=)

        translation.update!(is_published: true)

        expect(translation).to have_received(:translated_description=).ordered
        expect(s3_util).to have_received(:push_translation).ordered
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
