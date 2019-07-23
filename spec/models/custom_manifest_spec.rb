# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomManifest, type: :model do
  let(:structure) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:article="https://mobile-content-api.cru.org/xmlns/article"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
    <title><content:text i18n-id="name">About God</content:text></title>
</manifest>'
  end

  let(:resource) { Resource.first }
  let(:language) { Language.first }

  let(:empty_structure) do
    '<?xml version="1.0" encoding="UTF-8" ?>
<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
          xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
    <title><content:text i18n-id="title"></content:text></title>
</manifest>'
  end

  it 'cannot have a duplicate for resource and language' do
    described_class.create!(resource_id: resource.id, language_id: language.id, structure: structure)
    t = described_class.create(resource_id: resource.id, language_id: language.id, structure: structure)

    expect(t.errors['language']).to include('has already been taken')
  end

  it 'updates structure' do
    t = described_class.create!(resource_id: resource.id, language_id: language.id, structure: structure)
    t.update!(structure: empty_structure)

    expect(t.reload.structure).to include('i18n-id="title"')
  end

  it 'validates (XML) structure' do
    t = described_class.create(resource_id: resource.id, language_id: language.id, structure: '<invalid>XML')

    expect(t.errors['structure']).not_to be_empty
  end
end
