# frozen_string_literal: true

require 'rails_helper'
require 'page_util'
require 'xml_util'

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

  private

  def push
    page = Page.new(filename: 'test_page.xml')
    allow(XmlUtil).to receive(:translatable_nodes).with(anything).and_return([mock_xml_node(1, 'phrase 1'),
                                                                              mock_xml_node(2, 'phrase 2')])
    resource = Resource.new(pages: [page], onesky_project_id: 1)

    PageUtil.new(resource, 'de').push_new_onesky_translation
  end

  def mock_xml_node(id, text)
    node = double
    allow(node).to receive(:[]).with('i18n-id').and_return(id)
    allow(node).to receive(:content).and_return(text)
    node
  end
end
