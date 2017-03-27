# frozen_string_literal: true

require 'rails_helper'
require 'page_helper'

describe PageHelper do
  it 'downloads translated page from OneSky' do
    translation = Translation.find(2)
    result = PageHelper.download_translated_page(translation, '13_FinalPage.xml')
    values = JSON.parse(result)
    assert(values['3'] == 'This is a German phrase')
  end

  it 'deletes temp files' do
    allow(RestClient).to receive(:post)

    push

    pages_dir = Dir.glob('pages/*')
    assert(pages_dir.empty?)
  end

  it 'posts to OneSky' do
    expect(RestClient).to receive(:post).with('https://platform.api.onesky.io/1/projects/1/files', anything)

    push
  end

  private def push
    elements = [2]
    elements[0] = TranslationElement.new(id: 1, text: 'phrase 1')
    elements[1] = TranslationElement.new(id: 2, text: 'phrase 2')

    page = Page.new(filename: 'test_page.xml', translation_elements: elements)

    resource = Resource.new(pages: [page], onesky_project_id: 1)

    PageHelper.push_new_onesky_translation(resource, 'de')
  end
end
