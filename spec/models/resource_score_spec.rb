# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceScore, type: :model do
  let(:resource) { Resource.first }
  let(:language_en) { Language.find_or_create_by!(code: 'en', name: 'English') }
  let(:other_language) { Language.find_or_create_by!(code: 'fr', name: 'French') }
  subject(:resource_score) { FactoryBot.build(:resource_score, resource: resource, language: language_en) }

  describe 'validations' do
    let(:resource_score_with_resource) do
      FactoryBot.create(
        :resource_score, resource: resource, featured: true, featured_order: 1, country: 'US', language: language_en
      )
    end
    it { is_expected.to be_valid }

    context 'uniqueness validation' do
      let!(:previous_resource_score) do
        FactoryBot.create(:resource_score, resource: resource, country: 'us', language: language_en)
      end

      it 'validates uniqueness of resource_id scoped to country and language' do
        duplicate = FactoryBot.build(:resource_score, resource: resource, country: 'us', language: language_en)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:resource_id]).to include('should have only one ResourceScore per country and language')
      end
    end

    context 'featured validation' do
      it 'requires featured_order when featured is true' do
        resource_score.featured = true
        resource_score.featured_order = nil
        expect(resource_score).not_to be_valid
        expect(resource_score.errors[:featured_order]).to include('must be present if resource is featured')
      end

      it 'requires featured to be true if featured_order is assigned' do
        resource_score.featured = false
        resource_score.featured_order = 1
        expect(resource_score).not_to be_valid
        expect(resource_score.errors[:featured]).to include('must be true if a featured_order is assigned')
      end

      it 'validates uniqueness of featured_order within country, language and resource type' do
        resource_score_with_resource
        duplicate = ResourceScore.new(resource: resource, featured: true, featured_order: 1, country: 'us',
                                      language: language_en)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:featured_order]).to
        include('is already taken for this country, language and resource type')
      end

      context 'having a resource score created previously' do
        let!(:previous_resource_score) do
          ResourceScore.create(resource: resource, featured: true, featured_order: 1, country: 'us',
                               language: language_en)
        end

        it 'allows same featured_order for different country' do
          resource2 = Resource.last
          different_country = FactoryBot.build(:resource_score, resource: resource2, featured: true, featured_order: 1,
                                                                country: 'CA', language: language_en)
          expect(different_country).to be_valid
        end

        it 'allows same featured_order for different language' do
          resource2 = Resource.last
          different_lang = FactoryBot.build(:resource_score, resource: resource2, featured: true, featured_order: 1,
                                                             country: 'US', language: other_language)
          expect(different_lang).to be_valid
        end
      end

      it 'allows same featured_order for different resource type' do
        resource_score_with_resource
        different_resource_type = FactoryBot.build(
          :resource_score,
          resource: FactoryBot.create(:resource, resource_type: ResourceType.find_by(name: 'lesson')),
          featured: true,
          featured_order: 1,
          country: 'US',
          language: language_en
        )
        expect(different_resource_type).to be_valid
      end
    end
  end

  describe 'callbacks' do
    context 'before_save' do
      it 'downcases country' do
        resource_score.country = 'US'
        resource_score.save
        expect(resource_score.country).to eq('us')
      end
    end
  end
end
