# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  it 'downloads translated page from OneSky' do
    translation = Translation.find(2)
    result = translation.download_translated_page('13_FinalPage.xml')
    values = JSON.parse(result)
    expect(values['3']).to eq('This is a German phrase')
  end

  it 'increments version by one' do
    translation = Translation.find(1)
    new_translation = translation.create_new_version

    expect(new_translation.version).to be(2)
  end

  it 'replaces original pages with custom pages' do
    german_kgp = Translation.find(3)
    pages = german_kgp.translated_pages

    expect(pages[0].structure).to eq('<custom>This is some custom xml for one translation</custom>')
    expect(pages[1].structure).to eq('<note><to>Tove</to><from>Jani</from><heading>Reminder</heading>'\
                                 '<body>Dont forget me this weekend!</body></note>')
  end

  it 'returns latest version for resource/language combination' do
    translation = Translation.latest_translation(1, 2)
    expect(translation.version).to be(2)
  end

  it 'returns nil for resource/language combination that does not exist' do
    translation = Translation.latest_translation(1, 3)
    expect(translation).to be_nil
  end

  it 'returns the S3 URI as bucket/system name/resource abbreviation/language abbreviation' do
    ENV['GODTOOLS_V2_BUCKET'] = 'test_bucket'

    uri = Translation.find(1).s3_uri
    expect(uri).to eq('https://s3.amazonaws.com/test_bucket/GodTools/kgp/en/version_1.zip')
  end

  it 'returns bad request if deletion of a translation is attempted' do
    translation = Translation.find(1)

    expect { translation.destroy! }.to raise_error('Cannot delete published drafts.')
  end
end
