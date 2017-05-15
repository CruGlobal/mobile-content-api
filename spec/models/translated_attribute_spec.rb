# frozen_string_literal: true

require 'rails_helper'

describe TranslatedAttribute do
  it 'cannot be created with an un-translatable parent attribute' do
    attribute = Attribute.find(1)
    translation = Translation.find(1)

    expect do
      described_class.create!(parent_attribute: attribute, value: 'default', translation: translation)
    end.to raise_error('Parent attribute is not translatable.')
  end

  it 'attribute/translation combination must be unique' do
    attr = described_class.create(attribute_id: 2,
                                  translation_id: 3,
                                  value: 'foo')

    expect(attr).not_to be_valid
    expect(attr.errors[:translation]).to include('has already been taken')
  end
end
