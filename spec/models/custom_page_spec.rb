# frozen_string_literal: true

require 'rails_helper'

describe CustomPage do
  it 'cannot be replicated' do
    expect do
      CustomPage.create(translation_id: 3,
                        page_id: 1,
                        structure: '{ <xml>updated structure</xml> }')
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
