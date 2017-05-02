# frozen_string_literal: true

require 'rails_helper'

describe TranslatedAttribute do
  it 'cannot be created with an un-translatable parent attribute' do
    attribute = Attribute.find(1)
    translation = Translation.find(1)

    expect do
      TranslatedAttribute.create!(parent_attribute: attribute, value: 'default', translation: translation)
    end.to raise_error('Parent attribute is not translatable.')
  end

  it 'attribute/translation combination must be unique' do
    expect do
      TranslatedAttribute.create!(attribute_id: 2,
                                  translation_id: 3,
                                  value: 'foo')
    end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Translation has already been taken')
  end
end
