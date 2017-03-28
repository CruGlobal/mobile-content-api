# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  it 'downloads translated page from OneSky' do
    translation = Translation.find(2)
    result = translation.download_translated_page('13_FinalPage.xml')
    values = JSON.parse(result)
    assert(values['3'] == 'This is a German phrase')
  end

  it 'increments version by one' do
    translation = Translation.find(1)
    new_translation = translation.create_new_version

    assert(new_translation.version == 2)
  end

  it 'replaces original pages with custom pages' do
    german_kgp = Translation.find(3)
    pages = german_kgp.translation_pages_include_custom

    assert(pages[0].structure == '<custom>This is some custom xml for one translation</custom>')
    assert(pages[1].structure == '<note><to>Tove</to><from>Jani</from><heading>Reminder</heading>'\
                                 '<body>Dont forget me this weekend!</body></note>')
  end

  it 'returns latest version for resource/language combination' do
    translation = Translation.latest_translation(1, 2)
    assert(translation.version == 2)
  end

  it 'returns nil for resource/language combination that does not exist' do
    translation = Translation.latest_translation(1, 3)
    assert(translation.nil?)
  end
end
