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

  it 'increments version and creates new draft if resource/language combo exists' do
    post :create_draft, params: { resource_id: 1, language_id: 1 }

    translation = Translation.where(resource_id: 1, language_id: 1, version: 2).first
    assert(!translation.nil?)
  end

  it 'publishing draft sets published flag to true' do
    put :publish_draft, params: { id: 1 }

    translation = Translation.find(1)
    assert(translation.is_published)
  end
end
