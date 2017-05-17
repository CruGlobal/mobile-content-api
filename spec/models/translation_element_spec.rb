# frozen_string_literal: true

require 'rails_helper'

describe TranslationElement do
  it 'cannot be created for projects not using OneSky' do
    expect do
      described_class.create(text: 'hooray',
                             page_id: 3,
                             onesky_phrase_id: 'f6d2ee81-f952-423f-8fd5-a2ecfc08cd79')
    end.to(raise_error('Cannot be created for projects not using OneSky.'))
  end
end
