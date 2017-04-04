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
end
