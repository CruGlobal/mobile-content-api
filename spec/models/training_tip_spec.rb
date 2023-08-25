# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrainingTip, type: :model do
  context "create new training tip" do
    let!(:tip) { FactoryBot.create(:tip) }
    subject { TrainingTip.new(tool: "Tool 1", locale: "en", tip_id: tip.id, is_completed: true) }

    it "is valid" do
      expect(subject).to be_valid
    end
  end
end
