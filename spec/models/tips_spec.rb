# frozen_string_literal: true

require "rails_helper"

describe Tip do
  let(:id_1) { "5dadce9b-b881-439e-86b6-a2faac5367fc" }
  let(:id_2) { "df7795f5-d629-41f2-a94c-cacfc0b87125" }
  let(:id_3) { "f9894df9-df1d-4831-9782-345028c6c9a2" }

  let(:t_1) { "test phrase one" }
  let(:t_2) { "test phrase two" }
  let(:t_3) { "test phrase three" }

  let(:structure) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<page xmlns=\"https://mobile-content-api.cru.org/xmlns/tract\"
      xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
  <hero>
    <heading>
      <content:text i18n-id=\"#{id_1}\">#{t_1}</content:text>
    </heading>

    <content:paragraph>
      <content:text i18n-id=\"#{id_2}\">#{t_2}</content:text>
    </content:paragraph>

    <content:paragraph>
      <content:text i18n-id=\"#{id_3}\">#{t_3}</content:text>
    </content:paragraph>
  </hero>
</page>"
  end

  it "cannot duplicate a name" do
    described_class.create(resource_id: 1, name: "name", structure: structure)
    result = described_class.create(resource_id: 1, name: "name", structure: structure)

    expect(result.errors["name"]).to include("has already been taken")
  end
end
