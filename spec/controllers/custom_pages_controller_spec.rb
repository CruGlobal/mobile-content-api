# frozen_string_literal: true

require 'rails_helper'

describe CustomPagesController do
  it 'adds new translation page if translation id/page id combo does not exist' do
    post :create,
         params: { translation_id: 3,
                   page_id: 2,
                   structure: '<custom>This is some custom xml for one translation</custom>' }

    assert(response.status == 201)
    new_page = CustomPage.find_by(translation_id: 3, page_id: 2)
    assert(!new_page.nil?)
  end

  it 'updates structure of translation page if translation id/page id combo exists' do
    updated_structure = '<custom>This is some updated xml for one translation</custom>'
    post :create, params: { translation_id: 3, page_id: 1, structure: updated_structure }

    assert(response.status == 204)
    page = CustomPage.find_by(translation_id: 3, page_id: 1)
    assert(page.structure == updated_structure)
  end
end
