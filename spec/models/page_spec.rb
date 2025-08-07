# frozen_string_literal: true

require "rails_helper"

describe Page do
  let(:id_1) { "5dadce9b-b881-439e-86b6-a2faac5367fc" }
  let(:id_2) { "df7795f5-d629-41f2-a94c-cacfc0b87125" }
  let(:id_3) { "f9894df9-df1d-4831-9782-345028c6c9a2" }

  let(:p_1) { "test phrase one" }
  let(:p_2) { "test phrase two" }
  let(:p_3) { "test phrase three" }

  let(:structure) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<page xmlns=\"https://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <hero>
    <heading>
      <content:text i18n-id=\"#{id_1}\">#{p_1}</content:text>
    </heading>

    <content:paragraph>
      <content:text i18n-id=\"#{id_2}\">#{p_2}</content:text>
    </content:paragraph>

    <content:paragraph>
      <content:text i18n-id=\"#{id_3}\">#{p_3}</content:text>
    </content:paragraph>
  </hero>
</page>"
  end

  it "cannot duplicate Resource ID and Page position" do
    result = described_class.create(filename: "blahblah.xml", resource_id: 1, structure: structure, position: 1)

    expect(result.errors["position"]).to include("has already been taken")
  end

  it "cannot duplicate Resource ID and Filename" do
    result = described_class.create(filename: "04_ThirdPoint.xml", resource_id: 1, structure: structure, position: 2)

    expect(result.errors["filename"]).to include("has already been taken")
  end

  it "cannot be created for resource not using Crowdin" do
    result = described_class.create(filename: "blahblah.xml", resource_id: 3, structure: structure, position: 1)

    expect(result.errors["resource"]).to include("Does not use Crowdin.")
  end
end
