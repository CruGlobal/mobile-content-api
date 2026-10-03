# frozen_string_literal: true

require "rails_helper"

describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { FactoryBot.create(:user) }
  let(:record) { Language.find_or_create_by!(code: "en", name: "English") }

  it "exposes the user and record it was given" do
    expect(policy.user).to eq(user)
    expect(policy.record).to eq(record)
  end

  describe ApplicationPolicy::Scope do
    subject(:policy_scope) { described_class.new(user, scope) }

    let(:scope) { Language.all }

    it "exposes the user and scope it was given" do
      expect(policy_scope.user).to eq(user)
      expect(policy_scope.scope).to eq(scope)
    end

    it "raises, requiring subclasses to define their own scoping" do
      expect { policy_scope.resolve }.to raise_error(NoMethodError, /must define #resolve/)
    end
  end
end
