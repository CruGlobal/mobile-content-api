require 'rails_helper'

RSpec.describe ResourceScore, type: :model do
  let(:resource) { FactoryBot.create(:resource) }
  let(:resource_score) { FactoryBot.build(:resource_score, resource: resource) }

  it 'is valid with valid attributes' do
    expect(resource_score).to be_valid
  end

  it 'is not valid without a score' do
    resource_score.score = nil
    expect(resource_score).not_to be_valid
  end

  it 'is not valid with a score less than 1' do
    resource_score.score = 0
    expect(resource_score).not_to be_valid
  end

  it 'is not valid with a score greater than 20' do
    resource_score.score = 21
    expect(resource_score).not_to be_valid
  end

  it 'is not valid with a non-integer score' do
    resource_score.score = 5.5
    expect(resource_score).not_to be_valid
  end

  it 'is not valid with duplicate country and language for the same resource' do
    resource_score.save!
    duplicate_score = FactoryBot.build(:resource_score, resource: resource, country: resource_score.country,
                                                        lang: resource_score.lang)
    expect(duplicate_score).not_to be_valid
  end
end
