# frozen_string_literal: true

require 'rails_helper'

describe Translation do
  it 'increments version by one' do
    translation = Translation.find(1)
    translation.destroy
    new_translation = translation.add_new_version

    assert(new_translation.version == 2)
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
