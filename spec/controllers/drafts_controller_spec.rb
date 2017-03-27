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

  it 'pushes new draft to OneSky' do
    allow(PageHelper).to receive(:push_new_onesky_translation).with(
      Resource.find(1),
      Language.find(1).abbreviation
    ).and_return('OK')

    post :create_draft, params: { resource_id: 1, language_id: 1 }
  end
end
