# frozen_string_literal: true

require "equivalent-xml"
require "rails_helper"
require "xml_util"

describe XML::Manifest do
  let(:title) { "this is the kgp" }
  let(:translation) do
    t = Translation.find(1)
    allow(t).to(receive(:translated_name).and_return(title))
    allow(t).to(receive(:manifest_translated_phrases).and_return("name" => "Knowing God Personally",
                                                                 "description" => ""))
    t
  end

  context "manifest" do
    let(:pages) do
      Nokogiri::XML('<pages xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <page filename="04_ThirdPoint.xml" src="790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml"/>
        <page filename="13_FinalPage.xml" src="5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml"/>
      </pages>').root
    end
    let(:tips) do
      Nokogiri::XML('<tips xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <tip id="tip_name" src="kt6SxuuCU5M8AYmqpGjcWNNYCiCipEauybniinC5HrhF6h6KOvEZo8f5UhQUnRd.xml"/>
      </tips>').root
    end
    let(:resources) do
      Nokogiri::XML('<resources xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd"/>
      </resources>').root
    end

    let(:manifest) do
      m = described_class.new(translation)
      m.add_page("04_ThirdPoint.xml", "790a2170adb13955e67dee0261baff93cc7f045b22a35ad434435bdbdcec036a.xml")
      m.add_page("13_FinalPage.xml", "5ce1cd1be598eb31a76c120724badc90e1e9bafa4b03c33ce40f80ccff756444.xml")
      m.add_tip("tip_name", "kt6SxuuCU5M8AYmqpGjcWNNYCiCipEauybniinC5HrhF6h6KOvEZo8f5UhQUnRd.xml")
      m.add_resource("wall.jpg", "073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd")
      m
    end

    it "contains all pages in order" do
      result = XmlUtil.xpath_namespace(manifest.document, "//manifest:pages").first
      expect(result).to be_equivalent_to(pages)
    end

    it "contains all resources" do
      result = XmlUtil.xpath_namespace(manifest.document, "//manifest:resources").first
      expect(result).to be_equivalent_to(resources)
    end

    it "contains all tips in order" do
      result = XmlUtil.xpath_namespace(manifest.document, "//manifest:tips").first
      expect(result).to be_equivalent_to(tips)
    end

    it "contains tool code" do
      result = XmlUtil.xpath_namespace(manifest.document, "/manifest:manifest").first
      expect(result["tool"]).to eq(translation.resource.abbreviation)
    end

    it "contains tool locale" do
      result = XmlUtil.xpath_namespace(manifest.document, "/manifest:manifest").first
      expect(result["locale"]).to eq(translation.language.code)
    end

    it "contains tool type" do
      result = XmlUtil.xpath_namespace(manifest.document, "/manifest:manifest").first
      expect(result["type"]).to eq(translation.resource.resource_type.name)
    end

    it "contains translated title" do
      result = XmlUtil.xpath_namespace(manifest.document, "//manifest:title/content:text").first
      expect(result.content).to eq(title)
    end

    context "manifest with categories" do
      let(:title) { "Otázky o Bohu" }
      let(:translation) do
        t = Translation.find(1)
        t.resource.manifest = '<?xml version="1.0"?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:article="https://mobile-content-api.cru.org/xmlns/article"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content"
          category-label-color="rgba(255,255,255,1)">
    <title><content:text i18n-id="name">Questions about God</content:text></title>
    <categories>
        <category id="about-god" banner="banner-about-god.jpg">
           <label>
               <content:text i18n-id="about_god">About God</content:text>
           </label>
        </category>
        <category id="about-jesus" banner="about-jesus.jpg">
           <label>
              <content:text i18n-id="about_jesus">About Jesus</content:text>
           </label>
        </category>
        <category id="about-life" banner="about-life.jpg">
           <label>
               <content:text i18n-id="about_life">About Life</content:text>
           </label>
        </category>
        <category id="everything" banner="missing.jpg">
           <label>
               <content:text i18n-id="everything">Everything</content:text>
           </label>
        </category>
    </categories>
</manifest>'
        allow(t).to(receive(:translated_name).and_return(title))

        phrases = {
          # 'name' => '...',
          # 'description' => '',
          "about_god" => "O Bohu",
          "about_jesus" => "O Ježišovi",
          "about_life" => "O Živote",
          "everything" => "Všetko Ostatné",
        }
        allow(t).to(receive(:manifest_translated_phrases).and_return(phrases))

        t
      end

      let(:custom_manifest_structure) do
        '<?xml version="1.0"?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:article="https://mobile-content-api.cru.org/xmlns/article"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
<title><content:text i18n-id="name">About God</content:text></title>
<categories>
  <category id="about-god" banner="banner-about-god-custom.jpg">
    <label>
      <content:text i18n-id="about_god">The LORD</content:text>
    </label>
  </category>
</categories>
</manifest>'
      end
      let(:language) { translation.language }
      let(:custom_manifest) do
        translation.resource.custom_manifests.create! language: language, structure: custom_manifest_structure
      end

      it "translates title" do
        result = XmlUtil.xpath_namespace(manifest.document, "//manifest:title/content:text").first
        expect(result.content).to eq(title)
      end

      it "translates category content" do
        result = XmlUtil.xpath_namespace(manifest.document, "//manifest:category/manifest:label/content:text")
        expect(result.first.content).to eq("O Bohu")
        expect(result.last.content).to eq("Všetko Ostatné")
      end

      it "uses custom manifest structure when found" do
        custom_manifest
        expect(manifest.document.to_s).to include("banner-about-god-custom.jpg")
      end

      it "translates category content using custom manifest" do
        custom_manifest
        result = XmlUtil.xpath_namespace(manifest.document, "//manifest:category/manifest:label/content:text")
        expect(result.first.content).to eq("O Bohu")
      end

      it "translates using base manifest when custom manifest is for different language" do
        language = Language.create!(name: "czech", code: "cs", direction: "ltr")
        translation.resource.custom_manifests.create! language: language, structure: custom_manifest_structure

        expect(manifest.document.to_s).to include("banner-about-god.jpg")
        result = XmlUtil.xpath_namespace(manifest.document, "//manifest:category/manifest:label/content:text")
        expect(result.first.content).to eq("O Bohu")
      end
    end

    context "resource does not have a manifest file" do
      let(:translation) do
        t = Translation.find(8)
        allow(t).to(receive(:manifest_translated_phrases).and_return({}))
        t
      end

      it "creates manifest node" do
        result = XmlUtil.xpath_namespace(manifest.document, "/manifest:manifest")
        expect(result.size).to be(1)
      end

      it "has no title" do
        result = XmlUtil.xpath_namespace(manifest.document, "//manifest:title").first
        expect(result).to be_nil
      end
    end

    context "resource has a custom manifest without i18n-id attribute" do
      let(:translation) do
        t = Translation.find(1)
        t.resource.manifest = '<?xml version="1.0"?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:article="https://mobile-content-api.cru.org/xmlns/article"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
    <title><content:text i18n-id="name">Questions about God</content:text></title>
</manifest>'
        allow(t).to(receive(:translated_name).and_return("*Questions about God*"))
        allow(t).to(receive(:manifest_translated_phrases).and_return({}))

        t
      end

      let(:custom_manifest_structure) do
        '<?xml version="1.0" encoding="UTF-8" ?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:article="https://mobile-content-api.cru.org/xmlns/article"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
    <title><content:text>Renderer Testing (es)</content:text></title>
</manifest>'
      end
      let(:language) { translation.language }
      let(:custom_manifest) do
        translation.resource.custom_manifests.create! language: language, structure: custom_manifest_structure
      end

      it "uses custom manifest structure" do
        custom_manifest
        expect(manifest.document.to_s).to include("Renderer Testing (es)")
      end
    end
  end
end
