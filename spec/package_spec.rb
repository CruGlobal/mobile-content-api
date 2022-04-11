# frozen_string_literal: true

require "equivalent-xml"
require "rails_helper"
require "package"
require "xml_util"

describe Package do
  let(:translated_page_one_sha) { "ec9bac08c42c571a4df305171d04e196a5601af87e664600f1afba820b2a1a59" }
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
  let(:translated_page_two_sha) { "e9a07c177bb189cb1665307fffd770ad7c52316e0284a38fb8fa42f436b29397" }
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
  let!(:s3_object) { instance_double(Aws::S3::Object, upload_file: true) }
  let!(:s3_bucket) { mock_s3(s3_object, translation) }

  before do
    mock_onesky

    allow_any_instance_of(Attachment).to receive(:url) do |attachment|
      "#{fixture_path}/#{attachment.filename}"
    end

    allow(SecureRandom).to receive(:uuid).and_return(guid)
  end

  after do
   if Dir.exist?(directory)
      allow(PageClient).to receive(:delete_temp_dir).and_call_original
      PageClient.delete_temp_dir(directory)
    end
    if File.exists?("#{directory}/version_1.zip")
      verify_s3_uploads_match_zip 
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
  end

  it "zip file contains manifest" do
    mock_dir_deletion

    push

    expect_exists(translation.manifest_name)
  end

  it "zip file contains all attachments" do
    mock_dir_deletion

    push

    expect_exists("073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd")
  end

  context "manifest" do
    let(:manifest_sha) { "3ad7af4f4b41d41b4042a1bebe8cd72068ed6de16c51cd0903eb6fbfeb6304d9" }

    let(:page1_sha) { "ec9bac08c42c571a4df305171d04e196a5601af87e664600f1afba820b2a1a59" }
    let(:page2_sha) { "e9a07c177bb189cb1665307fffd770ad7c52316e0284a38fb8fa42f436b29397" }
    let(:pages) do
      Nokogiri::XML(%|<pages xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <page filename="04_ThirdPoint.xml" src="#{page1_sha}.xml"/>
        <page filename="13_FinalPage.xml" src="#{page2_sha}.xml"/>
      </pages>|).root
    end

    let(:resource1_sha) { "2cf2ab68c49b217c6b2402699c742a236f96efe36bc48821eb6ba1a1427b8945" }
    let(:resource1_filename) { "mobile_only.png" }
    let(:resource2_sha) { "4245551d69a8c582b6fc5185fb5312efc4f6863bda991a12a76102736f92fa2d" }
    let(:resource2_filename) { "web_mobile.png" }
    let(:resource3_sha) { "ad03ee4cc7b015919b375539db150dee5f47245c6a293663c21c774b2dba294f" }
    let(:resource3_filename) { "both.png" }
    let(:resource4_sha) { "073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd" }
    let(:resource4_filename) { "wall.jpg" }
    let(:resources) do
      Nokogiri::XML(%|<resources xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <resource filename="#{resource1_filename}" src="#{resource1_sha}"/>
        <resource filename="#{resource2_filename}" src="#{resource2_sha}"/>
        <resource filename="#{resource3_filename}" src="#{resource3_sha}"/>
        <resource filename="#{resource4_filename}" src="#{resource4_sha}"/>
      </resources>|).root
    end

    let(:tip1_sha) { "c26f707f414bbfda0656d890867d7da90058d8d0303dce8daef80951760cd56d" }
    let(:tip2_sha) { "503fa579c48f89d3e7428e3a3f24fae80b43bf97b53318309696a093298ae032" }
    let(:tips) do
      Nokogiri::XML(%|<tips xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <tip id="tip1" src="#{tip1_sha}.xml"/>
        <tip id="tip2" src="#{tip2_sha}.xml"/>
      </tips>|).root
    end
    let(:title) { "this is the kgp" }

    let!(:language_attribute) do
      FactoryBot.create(:language_attribute, resource: resource, language: translation.language, key: "include_tips", value: "true")
    end

		let(:generated_manifest_sha) { "3ad7af4f4b41d41b4042a1bebe8cd72068ed6de16c51cd0903eb6fbfeb6304d9" }

    before do
      mock_dir_deletion
    end

    def expect_s3_to_have(path, body, sha)
      expect(s3_bucket).to receive(:object).with(path).and_return(s3_object)
      expect(s3_object).to receive(:put).with(acl: "public-read", body: body, checksum_sha256: sha).and_return(true)
    end

    it "contains all pages in order" do
      push

      result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:pages").first
      expect(result).to be_equivalent_to(pages)
    end

    it "contains all referenced resources" do
      push

      result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:resources").first
      expect(result).to be_equivalent_to(resources)
    end

    context "include_tips false" do
      it "does not reference tips" do
        LanguageAttribute.delete_all
        expect_s3_to_have("#{translated_page_one_sha}.xml", translated_page_one, translated_page_one_sha)
        expect_s3_to_have("#{translated_page_two_sha}.xml", translated_page_two, translated_page_two_sha)
        expect_s3_to_have(resource1_sha, File.read("spec/fixtures/#{resource1_filename}"), resource1_sha)
        expect_s3_to_have(resource2_sha, File.read("spec/fixtures/#{resource2_filename}"), resource2_sha)
        expect_s3_to_have(resource3_sha, File.read("spec/fixtures/#{resource3_filename}"), resource3_sha)
        expect_s3_to_have(resource4_sha, File.read("spec/fixtures/#{resource4_filename}"), resource4_sha)
        expect_s3_to_have("#{generated_manifest_sha}.xml", File.read("spec/fixtures/#{generated_manifest_sha}.xml"), generated_manifest_sha)
        push

        result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:tips").first
        expect(result).to_not be_equivalent_to(tips)
      end
    end

    context "include_tips true" do
      it "contains all referenced tips" do
        push

        result = XmlUtil.xpath_namespace(load_xml(translation.manifest_name), "//manifest:tips").first
        expect(result).to be_equivalent_to(tips)
      end
    end

    it "contains translated title" do
      allow(translation).to receive(:translated_name).and_return(title)
      push

      manifest = load_xml(translation.manifest_name)
      result = manifest.xpath("//content:text[@i18n-id='89a09d72-114f-4d89-a72c-ca204c796fd9']").first
      expect(result.content).to eq(title)
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

  def mock_onesky(project_id = nil)
    ENV["ONESKY_API_SECRET"] ||= ""
    project_id ||= Resource.find(1).onesky_project_id
    response = RestClient::Response.new('{ "1":"value" }')
    response.instance_variable_set :@code, 200
    allow(RestClient).to receive(:get)
      .with("https://platform.api.onesky.io/1/projects/#{project_id}/translations", any_args)
      .and_return(response)
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
      [entry.name, {body: data.force_encoding("UTF-8"), checksum: Digest::SHA256.hexdigest(data)}] # zip seems to get data in ASCII but s3 uploads in UTF-8, they fail comparison check otherwise
    end.to_h

    from_s3 = @s3_uploads.collect do |path, upload|
      [path, {body: upload[:body], checksum: upload[:checksum_sha256]}]
    end.to_h 

    from_zip_checksums_only = from_zip.collect{ |k, v| [k, v[:checksum]] }.to_h
    from_s3_checksums_only = from_s3.collect{ |k, v| [k, v[:checksum]] }.to_h

    # to make differences easier to mentally parse (and not print out big file contents), ensure the paths are the same first, then checksums
    expect(from_zip.keys).to eq(from_s3.keys)
    expect(from_zip_checksums_only).to eq(from_s3_checksums_only)
    expect(from_zip).to eq(from_s3)
  end
end
