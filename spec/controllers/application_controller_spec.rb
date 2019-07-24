# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController do
  controller do
    def index
      head(204)
    end
    public :param?, :params
  end

  # rubocop: disable BeforeAfterAll
  before(:all) do
    Mime::Type.register 'application/vnd.api+json', :json_api
  end

  it 'params are not merged if no body' do
    set_method_and_jsonapi_headers 'DELETE'

    delete :index, body: String.new('')

    expect(response).to have_http_status(:no_content)
  end

  it 'empty and missing params are false-y' do
    set_method_and_jsonapi_headers 'GET'

    get :index, params: { foo: '', bar: '   ' }

    expect(controller.param?(:foo)).to be_falsey
    expect(controller.param?('bar')).to be_falsey
    expect(controller.param?(:baz)).to be_falsey
  end

  it 'zero params are false-y' do
    set_method_and_jsonapi_headers 'GET'

    get :index, params: { 'foo' => '0', 'bar' => 0 }

    expect(controller.param?(:foo)).to be_falsey
    expect(controller.param?(:bar)).to be_falsey
  end

  it 'non-zero params are truthy-y' do
    set_method_and_jsonapi_headers 'GET'

    get :index, params: { 'foo' => '1', 'bar' => 1, :baz => '01' }

    expect(controller.param?(:foo)).to be true
    expect(controller.param?(:bar)).to be true
    expect(controller.param?(:baz)).to be true
  end

  it 'non-blank strings are truthy-y' do
    set_method_and_jsonapi_headers 'GET'

    get :index, params: { 'foo' => 'X', 'bar' => ' . ', :baz => '[]' }

    expect(controller.param?(:foo)).to be true
    expect(controller.param?(:bar)).to be true
    expect(controller.param?(:baz)).to be true
  end

  it 'true/false params are converted to boolean' do
    set_method_and_jsonapi_headers 'GET'

    get :index, params: { 'foo' => 'true', 'bar' => 'false' }

    expect(controller.param?(:foo)).to be true
    expect(controller.param?(:bar)).to be false
  end

  # rubocop:disable AccessorMethodName
  def set_method_and_jsonapi_headers(method = 'GET')
    request.headers['REQUEST-METHOD'] = method
    request.headers['Content-Type'] = 'application/vnd.api+json'
  end
end
