# frozen_string_literal: true

require 'rails_helper'
require 'puma/null_io'

describe ApplicationController do
  controller do
    def index; end
  end

  it 'params are not merged if no body' do
    Mime::Type.register 'application/vnd.api+json', :json_api
    request.headers['REQUEST-METHOD'] = 'DELETE'
    request.headers['Content-Type'] = 'application/vnd.api+json'

    delete :index, body: String.new('')

    expect(response).to have_http_status(:no_content)
  end
end
