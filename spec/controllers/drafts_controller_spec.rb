# frozen_string_literal: true

require 'rails_helper'

describe DraftsController do
  it 'downloads translated page with correct filename' do
    result = '{ \"1\": \"phrase\" }'
    allow(PageHelper).to receive(:download_translated_page).with(Translation.find(2),
                                                                 Page.find(1).filename).and_return(result)
    get :page, params: { draft_id: 2, page_id: 1 }
    assert(response.body == result)
  end

  it 'pushes new draft to OneSky if resource/language combo does not exist' do
    expect(PageHelper).to receive(:push_new_onesky_translation).with(
      Resource.find(1),
      Language.find(3).abbreviation
    )
    post :create_draft, params: { resource_id: 1, language_id: 3 }
  end

  it 'creates new draft if resource/language combo does not exist' do
    expect(PageHelper).to receive(:push_new_onesky_translation).with(anything, anything)
    post :create_draft, params: { resource_id: 1, language_id: 3 }

    translation = Translation.where(resource_id: 1, language_id: 3, version: 1).first
    assert(!translation.nil?)
  end

  it 'does not push to OneSky if resource/language combo exists' do
    expect(PageHelper).to_not receive(:push_new_onesky_translation).with(anything, anything)
    post :create_draft, params: { resource_id: 1, language_id: 1 }
  end

  it 'increments version and creates new draft if resource/language translation exists' do
    post :create_draft, params: { resource_id: 1, language_id: 1 }

    translation = Translation.where(resource_id: 1, language_id: 1, version: 2).first
    assert(!translation.nil?)
  end

  it 'bad request returned if resource/language draft exists' do
    post :create_draft, params: { resource_id: 1, language_id: 2 }

    assert(response.status == 400)
    assert(response.body == 'Draft already exists for this resource and language.')
  end

  it 'adds new translation page if translation id/page id combo does not exist' do
    put :add_page_structure_for_one_translation,
        params: { id: 3, page_id: 2, structure: '<custom>This is some custom xml for one translation</custom>' }

    assert(response.status == 201)
    new_page = CustomPage.find_by(translation_id: 3, page_id: 2)
    assert(!new_page.nil?)
  end

  it 'updates structure of translation page if translation id/page id combo exists' do
    updated_structure = '<custom>This is some updated xml for one translation</custom>'
    put :add_page_structure_for_one_translation, params: { id: 3, page_id: 1, structure: updated_structure }

    assert(response.status == 204)
    page = CustomPage.find_by(translation_id: 3, page_id: 1)
    assert(page.structure = updated_structure)
  end

  it 'publishing draft sets published flag to true' do
    put :publish_draft, params: { id: 1 }

    translation = Translation.find(1)
    assert(translation.is_published)
  end

  it 'delete draft' do
    delete :delete_draft, params: { id: 3 }

    assert(response.status == 204)
  end

  it 'cannot delete translations' do
    delete :delete_draft, params: { id: 1 }

    assert(response.status == 400)
    assert(response.body == 'Cannot delete published translations.')
  end
end
