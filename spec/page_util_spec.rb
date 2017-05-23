# frozen_string_literal: true

require 'rails_helper'
require 'page_util'

describe PageUtil do
  it 'deletes all temp files after successful request' do
    allow(RestClient).to receive(:post)

    push

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  it 'deletes all temp files if error is raised' do
    allow(RestClient).to receive(:post).and_raise(StandardError)

    expect { push }.to raise_error(StandardError)

    pages_dir = Dir.glob('pages/*')
    expect(pages_dir).to be_empty
  end

  it 'posts to OneSky' do
    allow(RestClient).to receive(:post)

    push

    expect(RestClient).to have_received(:post).with('https://platform.api.onesky.io/1/projects/1/files', anything)
  end

  private def push
    elements = [OneskyPhrase.new(id: 1, text: 'phrase 1'), OneskyPhrase.new(id: 2, text: 'phrase 2')]
    page = Page.new(filename: 'test_page.xml', onesky_phrases: elements)
    resource = Resource.new(pages: [page], onesky_project_id: 1)

    PageUtil.new(resource, 'de').push_new_onesky_translation
  end
end
