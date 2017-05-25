# frozen_string_literal: true

require 'rails_helper'

describe TranslatedPage do
  it 'cannot be created for projects not using OneSky' do
    expect do
      described_class.create(value: 'what a beautiful day',
                             page_id: 1,
                             translation_id: 3)
    end.to(raise_error('Cannot be created for projects using OneSky.'))
  end
end
