# frozen_string_literal: true

require 'rails_helper'
require 'page_util'

describe ResourcesController do
  let(:resource_id) { 1 }

  it 'includes latest translations by default' do
    get :show, params: { id: resource_id }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['included'].count).to be(2)
  end

  it 'includes all when specified' do
    get :show, params: { id: resource_id, include: :translations }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['included'].count).to be(3)
  end
end
