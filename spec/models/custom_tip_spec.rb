require "rails_helper"

RSpec.describe CustomTip, type: :model do
  let(:language_id) { 2 }
  let(:structure) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
  xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
	<pages>
	</pages>
</tip>'
  end
  let!(:tip) { FactoryBot.create(:tip, resource: Resource.first, structure: structure) }
  let(:structure2) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
  xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <pages>
	  <page>
	    <content:paragraph>
	      <content:text />
	    </content:paragraph>
	    <content:text />
	  </page>
	</pages>
</tip>'
  end

  it "Language/Tip combination cannot be replicated" do
    described_class.create(language_id: language_id, tip_id: tip.id, structure: structure2)
    result = described_class.create(language_id: language_id, tip_id: tip.id, structure: structure2)

    expect(result.errors[:language]).to include "has already been taken"
  end
end
