# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserTrainingTip, type: :model do
  context "create new training tip" do
    let(:tip_id) { "tip" }
    let(:user) { FactoryBot.create(:user) }
    let(:tool) { Resource.first }
    let(:language) { Language.first }

    subject { UserTrainingTip.new(tool_id: tool.id, language_id: language.id, tip_id: tip_id, is_completed: true, user: user) }

    it "is valid" do
      expect(subject).to be_valid
    end
  end
end
