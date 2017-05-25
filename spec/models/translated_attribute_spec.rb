# frozen_string_literal: true

require 'rails_helper'

describe TranslatedAttribute do
  it 'cannot be created with an un-translatable parent attribute' do
    parent_attribute_id = 1
    attribute = Attribute.find(parent_attribute_id)
    translation = Translation.find(1)

    expect { described_class.create!(parent_attribute: attribute, value: 'default', translation: translation) }
      .to raise_error("Parent attribute with ID: #{parent_attribute_id} is not translatable.")
  end

  it 'attribute/translation combination must be unique' do
    attr = described_class.create(attribute_id: 2,
                                  translation_id: 3,
                                  value: 'foo')

    expect(attr).not_to be_valid
    expect(attr.errors[:translation]).to include('has already been taken')
  end
end
