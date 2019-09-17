# frozen_string_literal: true

require "equivalent-xml"
require "rails_helper"
require "package"
require "xml_util"

describe Package do
  let(:translated_page_one) do
    '<?xml version="1.0" encoding="UTF-8"?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content"
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
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
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

  before do
    mock_onesky

    mock_s3(instance_double(Aws::S3::Object, upload_file: true), translation)

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

    expect_exists("71edacf514e76a1068454ef9dc219dfa36cd4394757b4a4bf2cee18b9e18559a.xml")
    expect_exists("f5861440733ca31e99a04b9dd880ba3eeae314560d9197583bdbda0cb5c4c265.xml")
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
    let(:pages) do
      Nokogiri::XML('<pages xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <page filename="04_ThirdPoint.xml" src="71edacf514e76a1068454ef9dc219dfa36cd4394757b4a4bf2cee18b9e18559a.xml"/>
        <page filename="13_FinalPage.xml" src="f5861440733ca31e99a04b9dd880ba3eeae314560d9197583bdbda0cb5c4c265.xml"/>
      </pages>').root
    end
    let(:resources) do
      Nokogiri::XML('<resources xmlns="https://mobile-content-api.cru.org/xmlns/manifest">
        <resource filename="mobile_only.png" src="2cf2ab68c49b217c6b2402699c742a236f96efe36bc48821eb6ba1a1427b8945"/>
        <resource filename="web_mobile.png" src="4245551d69a8c582b6fc5185fb5312efc4f6863bda991a12a76102736f92fa2d"/>
        <resource filename="both.png" src="ad03ee4cc7b015919b375539db150dee5f47245c6a293663c21c774b2dba294f"/>
        <resource filename="wall.jpg" src="073d78ef4dc421f10d2db375414660d3983f506fabdaaff0887f6ee955aa3bdd"/>
      </resources>').root
    end
    let(:title) { "this is the kgp" }

    before do
      mock_dir_deletion
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
end
