FactoryBot.define do
  factory :custom_tip do
    structure do
      <<~XML
        <tip xmlns=\"https://mobile-content-api.cru.org/xmlns/training\" xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\" type=\"prepare\">
          <pages>
            <page>
              <content:paragraph>
                <content:text />
                <content:text />
              </content:paragraph>
            </page>
          </pages>
        </tip>
      XML
    end
    association :tip
    language_id { 1 }
  end
end
