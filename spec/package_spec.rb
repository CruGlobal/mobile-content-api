# frozen_string_literal: true

require "equivalent-xml"
require "rails_helper"

describe Package do
  let(:translated_page_one) do
    '<?xml version="1.0" encoding="UTF-8"?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content"
      xmlns:training="https://mobile-content-api.cru.org/xmlns/training"
      primary-color="rgba(59,164,219,1)" primary-text-color="rgba(255,255,255,1)"
      background-image="wall.jpg">
  <header>
    <number>
      <content:text>999</content:text>
    </number>
    <title>
      <content:text>Header Title (Default)</content:text>
    </title>
  </header>
  <hero>
    <heading>
      <content:text>Hero Heading</content:text>
    </heading>

    <content:paragraph>
      <content:text>paragraph 1 - line 1</content:text>
      <content:text>paragraph 1 - line 2</content:text>
      <content:text>paragraph 1 - line 3</content:text>
      <content:text>p1 - l4</content:text>
      <training:tip id="tip1" />
      <training:tip id="tip2" />
    </content:paragraph>
    <content:paragraph>
      <content:text>paragraph 2 - line 1</content:text>
      <content:text>paragraph 2 - line 2</content:text>
      <content:text>paragraph 2 - line 3</content:text>
    </content:paragraph>
  </hero>
</page>
'
  end
  let(:translated_page_two) do
    '<?xml version="1.0" encoding="UTF-8"?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content"
      xmlns:training="https://mobile-content-api.cru.org/xmlns/training">
  <hero>
    <heading>
      <content:text i18n-id="image_restrict_to_title">Image restrictTo testing</content:text>
    </heading>

    <content:paragraph>
      <content:text>web_bundled.png</content:text>
      <content:text>before</content:text>
      <content:image resource="web_bundled.png" restrictTo="web"/>
      <content:text>after</content:text>
    </content:paragraph>
    <content:paragraph>
      <content:text>web_attach.png</content:text>
      <content:text>before</content:text>
      <content:image resource="web_attach.png" restrictTo="web"/>
      <content:text>after</content:text>
    </content:paragraph>
    <content:paragraph>
      <content:text>mobile_only.png</content:text>
      <content:text>before</content:text>
      <content:image resource="mobile_only.png" restrictTo="mobile"/>
      <content:text>after</content:text>
    </content:paragraph>
    <content:paragraph>
      <content:text>web_mobile.png</content:text>
      <content:text>before</content:text>
      <content:image resource="web_mobile.png" restrictTo="web mobile"/>
      <content:text>after</content:text>
    </content:paragraph>
    <content:paragraph>
      <content:text>both.png</content:text>
      <content:text>before</content:text>
      <content:image resource="both.png"/>
      <content:text>after</content:text>
    </content:paragraph>
  </hero>
</page>
'
  end
  let(:translation) do
    t = Translation.find(1)
    t.translated_name = "Knowing God Personally!"
    allow(t).to(receive(:translated_page).and_return(translated_page_one, translated_page_two))
    t
  end

  let(:guid) { "32ef5884-9004-47d8-9285-bb5b2205e554" }
  let(:directory) { "pages/#{guid}" }
  let(:resource) { Resource.first }
  let(:tip_structure) do
    %(<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
        xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
          <pages>
              <page>
                  <content:paragraph>
                      <content:text />
                  </content:paragraph>
                  <content:text />
              </page>
          </pages>
      </tip>)
  end
  let!(:tip1) { FactoryBot.create(:tip, name: "tip1", resource: resource, structure: tip_structure) }
  let(:tip_structure2) do
    %(<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
        xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
          <pages>
              <page>
                  <content:paragraph>
                      <content:text />
                  </content:paragraph>
                  <content:paragraph>
                      <content:text />
                  </content:paragraph>
                  <content:text />
              </page>
          </pages>
      </tip>)
  end
  let!(:tip2) { FactoryBot.create(:tip, name: "tip2", resource: resource, structure: tip_structure2) }

  before do
    mock_onesky

    mock_s3(instance_double(Aws::S3::Object, upload_file: true), translation)

    allow_any_instance_of(Attachment).to receive(:url) do |attachment|
      "#{fixture_paths.first}/#{attachment.filename}"
    end

    allow(SecureRandom).to receive(:uuid).and_return(guid)
  end

  after do
    if Dir.exist?(directory)
      allow(PageClient).to receive(:delete_temp_dir).and_call_original
      PageClient.delete_temp_dir(directory)
    end
  end

  it "deletes temp directory after successful request" do
    push

    pages_dir_nil
  end

  it "deletes temp directory if error is raised" do
    object = instance_double(Aws::S3::Object)
    allow(object).to receive(:upload_file).and_raise(StandardError)
    mock_s3(object, translation)

    expect { push }.to raise_error(StandardError)

    pages_dir_nil
  end

  it "zip file contains all pages" do
    mock_dir_deletion

    push

    expect_exists("ec9bac08c42c571a4df305171d04e196a5601af87e664600f1afba820b2a1a59.xml")
    expect_exists("e9a07c177bb189cb1665307fffd770ad7c52316e0284a38fb8fa42f436b29397.xml")
    verify_s3_uploads_match_zip
  end

  it "zip file contains manifest" do
    mock_dir_deletion

    push

    expect_exists(translation.manifest_name)
    verify_s3_uploads_match_zip
  end

  it "zip file contains all attachments" do
    mock_dir_deletion

    push

    expect_exists("073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd.jpg")
    verify_s3_uploads_match_zip
  end

  context "manifest" do
    let(:pages) do
      Nokogiri::XML('<pages xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <page filename="04_ThirdPoint.xml" src="ec9bac08c42c571a4df305171d04e196a5601af87e664600f1afba820b2a1a59.xml"/>
        <page filename="13_FinalPage.xml" src="e9a07c177bb189cb1665307fffd770ad7c52316e0284a38fb8fa42f436b29397.xml"/>
      </pages>').root
    end
    let(:resources) do
      Nokogiri::XML('<resources xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <resource filename="web_bundled.png" src="d028ba4dc56eb5ac641f19eeca5baa25d748ab303b32a5580f601e112a19b9f5.png"/>
        <resource filename="web_attach.png" src="97c82df868bcd36afcb4b0af912a06c93782d47e9edc35604d9a4dc31afb0e47.png"/>
        <resource filename="mobile_only.png" src="2cf2ab68c49b217c6b2402699c742a236f96efe36bc48821eb6ba1a1427b8945.png"/>
        <resource filename="web_mobile.png" src="4245551d69a8c582b6fc5185fb5312efc4f6863bda991a12a76102736f92fa2d.png"/>
        <resource filename="both.png" src="ad03ee4cc7b015919b375539db150dee5f47245c6a293663c21c774b2dba294f.png"/>
        <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd.jpg"/>
      </resources>').root
    end
    let(:tips) do
      Nokogiri::XML('<tips xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <tip id="tip1" src="c26f707f414bbfda0656d890867d7da90058d8d0303dce8daef80951760cd56d.xml"/>
        <tip id="tip2" src="503fa579c48f89d3e7428e3a3f24fae80b43bf97b53318309696a093298ae032.xml"/>
      </tips>').root
    end
    let(:title) { "this is the kgp" }

    let!(:language_attribute) do
      FactoryBot.create(:language_attribute, resource: resource, language: translation.language, key: "include_tips", value: "true")
    end

    before do
      mock_dir_deletion
    end

    it "contains all pages in order" do
      push

      result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:pages").first
      expect(result).to be_equivalent_to(pages)
      verify_s3_uploads_match_zip
    end

    it "contains all referenced resources" do
      push

      result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:resources").first
      expect(result).to be_equivalent_to(resources)
      verify_s3_uploads_match_zip
    end

    context "include_tips false" do
      it "does not reference tips" do
        LanguageAttribute.delete_all
        push

        result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:tips").first
        expect(result).to_not be_equivalent_to(tips)
        verify_s3_uploads_match_zip
      end
    end

    context "include_tips true" do
      it "contains all referenced tips" do
        push

        result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:tips").first
        expect(result).to be_equivalent_to(tips)
        verify_s3_uploads_match_zip
      end
    end

    it "contains translated title" do
      allow(translation).to receive(:translated_name).and_return(title)
      push

      manifest = load_xml(translation.manifest_name)
      result = manifest.xpath("//content:text[@i18n-id='89a09d72-114f-4d89-a72c-ca204c796fd9']").first
      expect(result.content).to eq(title)
      verify_s3_uploads_match_zip
    end

    context "resource does not have a manifest file" do
      let(:translation) do
        t = Translation.find(8)
        allow(t).to(receive(:translated_page).and_return(translated_page_one, translated_page_two))
        t
      end

      it "creates manifest node" do
        mock_onesky translation.resource.onesky_project_id

        push

        manifest = load_xml(translation.manifest_name)
        expect(manifest.xpath("/m:manifest", "m" => XmlUtil::XMLNS_MANIFEST).size).to be(1)
      end
    end

    context "page missing resource" do
      let(:translated_page_one) do
        '<?xml version="1.0" encoding="UTF-8"?>
           <page xmlns="https://mobile-content-api.cru.org/xmlns/tract" background-image="missing.jpg"></page>'
      end

      it "raises an exception" do
        expect { push }.to raise_error(ActiveRecord::RecordNotFound, "Attachment not found: missing.jpg")
      end
    end

    context "page missing tip" do
      let(:translated_page_one) do
        '<?xml version="1.0" encoding="UTF-8"?>
    <page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content"
          xmlns:training="https://mobile-content-api.cru.org/xmlns/training"
          primary-color="rgba(59,164,219,1)" primary-text-color="rgba(255,255,255,1)"
          background-image="wall.jpg">
      <hero>
        <content:paragraph>
          <training:tip id="tip1" />
          <training:tip id="missing" />
        </content:paragraph>
      </hero>
    </page>
    '
      end

      context("with include_tips true") do
        it "raises an exception" do
          expect { push }.to raise_error(ActiveRecord::RecordNotFound, "Tip not found: missing")
        end
      end

      context("with include_tips false") do
        it "raises an exception" do
          LanguageAttribute.first.update(value: "false")
          expect { push }.to_not raise_error
        end
      end

      context("with include_tips nil") do
        it "raises an exception" do
          LanguageAttribute.delete_all
          expect { push }.to_not raise_error
        end
      end
    end

    context "translation missing i18n title" do
      it "fails to push" do
        translation.translated_name = nil

        expect { push }.to raise_error(Error::TextNotFoundError)
      end
    end
  end

  it "always uses strict mode" do
    push

    expect(translation).not_to(have_received(:translated_page).with(any_args, false))
  end

  private

  def load_xml(name)
    Nokogiri::XML(File.open("#{directory}/#{name}"))
  end

  def open_zip_file
  end

  def expect_exists(filename)
    file = Zip::File.open("#{directory}/version_1.zip").get_entry(filename)
    expect(file).not_to be_nil
  end

  def pages_dir_nil
    expect(Dir.exist?(directory)).to be_falsey
  end

  def mock_dir_deletion
    allow(PageClient).to receive(:delete_temp_dir)
  end

  def push
    mock_onesky
    package = Package.new(translation)
    package.push_to_s3
  end

  def verify_s3_uploads_match_zip
    # build two hashes of path => { body: ..., checksum: ... } from s3 uploads and from the zip, and compare those

    from_zip = Zip::File.open("#{directory}/version_1.zip").entries.collect do |entry|
      data = entry.get_input_stream.read

      # zip seems to get data in ASCII but s3 uploads in UTF-8, they fail comparison check otherwise
      data = data.force_encoding("UTF-8")
      checksum = Base64.encode64([Digest::SHA256.hexdigest(data)].pack("H*")).strip
      [Package::TRANSLATION_FILES_PATH + entry.name, {body: data, checksum: checksum}]
    end.to_h

    from_s3 = @s3_uploads.collect do |path, upload|
      [path, {body: upload[:body], checksum: upload[:checksum_sha256]}]
    end.to_h

    from_zip_checksums_only = from_zip.collect { |k, v| [k, v[:checksum]] }.to_h
    from_s3_checksums_only = from_s3.collect { |k, v| [k, v[:checksum]] }.to_h

    # to make differences easier to mentally parse (and not print out big file contents), ensure the paths are the same first, then checksums
    expect(from_zip.keys).to match_array(from_s3.keys)
    expect(from_zip_checksums_only).to match_array(from_s3_checksums_only)
    expect(from_zip).to eql(from_s3)
  end
end
