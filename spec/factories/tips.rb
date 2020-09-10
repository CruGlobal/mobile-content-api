FactoryBot.define do
  factory :tip do
    structure do
      <<~XML
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
        </tip>
      XML
    end
    sequence :name do |n|
      "name_#{n}"
    end
    resource do
      Resource.first || create(:resource)
    end
  end
end
