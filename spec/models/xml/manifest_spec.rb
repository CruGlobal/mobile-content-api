# frozen_string_literal: true

require 'equivalent-xml'
require 'rails_helper'
require 'xml_util'

describe XML::Manifest do
  let(:title) { 'this is the kgp' }
  let(:translation) do
    t = Translation.find(1)
    allow(t).to(receive(:translated_name).and_return(title))
    allow(t).to(receive(:manifest_translated_phrases).and_return('name' => 'Knowing God Personally',
                                                                 'description' => ''))
    t
  end

  context 'manifest' do
    let(:pages) do
      Nokogiri::XML('<pages xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <page filename="04_ThirdPoint.xml" src="790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml"/>
        <page filename="13_FinalPage.xml" src="5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml"/>
      </pages>').root
    end
    let(:resources) do
      Nokogiri::XML('<resources xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd"/>
      </resources>').root
    end

    let(:manifest) do
      m = described_class.new(translation)
      m.add_page('04_ThirdPoint.xml', '790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml')
      m.add_page('13_FinalPage.xml', '5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml')
      m.add_resource('wall.jpg', '073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd')
      m
    end

    it 'contains all pages in order' do
      result = XmlUtil.xpath_namespace(manifest.document, '//manifest:pages').first
      expect(result).to be_equivalent_to(pages)
    end

    it 'contains all resources' do
      result = XmlUtil.xpath_namespace(manifest.document, '//manifest:resources').first
      expect(result).to be_equivalent_to(resources)
    end

    it 'contains tool code' do
      result = XmlUtil.xpath_namespace(manifest.document, '/manifest:manifest').first
      expect(result['tool']).to eq(translation.resource.abbreviation)
    end

    it 'contains tool locale' do
      result = XmlUtil.xpath_namespace(manifest.document, '/manifest:manifest').first
      expect(result['locale']).to eq(translation.language.code)
    end

    it 'contains tool type' do
      result = XmlUtil.xpath_namespace(manifest.document, '/manifest:manifest').first
      expect(result['type']).to eq(translation.resource.resource_type.name)
    end

    it 'contains translated title' do
      result = XmlUtil.xpath_namespace(manifest.document, '//manifest:title/content:text').first
      expect(result.content).to eq(title)
    end

    context 'resource does not have a manifest file' do
      let(:translation) do
        t = Translation.find(8)
        allow(t).to(receive(:manifest_translated_phrases).and_return({}))
        t
      end

      it 'creates manifest node' do
        result = XmlUtil.xpath_namespace(manifest.document, '/manifest:manifest')
        expect(result.size).to be(1)
      end

      it 'has no title' do
        result = XmlUtil.xpath_namespace(manifest.document, '//manifest:title').first
        expect(result).to be_nil
      end
    end
  end
end
