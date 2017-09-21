# frozen_string_literal: true

require 'rails_helper'

describe TranslatedAttribute do
  it 'cannot be created with an un-translatable parent attribute' do
    result = described_class.create(parent_attribute: Attribute.find(1),
                                    value: 'default',
                                    translation: Translation.find(1))

    expect(result.errors['parent-attribute']).to include('Is not translatable.')
  end

  it 'attribute/translation combination must be unique' do
    attr = described_class.create(attribute_id: 2,
                                  translation_id: 3,
                                  value: 'foo')

    expect(attr.errors[:translation]).to include('has already been taken')
  end
end
