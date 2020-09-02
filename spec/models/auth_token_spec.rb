# frozen_string_literal: true

require "rails_helper"

include ActiveSupport::Testing::TimeHelpers

describe AuthToken do
  describe '.generic_token' do
    subject { described_class.generic_token }

    it "generates a jwt" do
      expect(subject).not_to be_nil
      expect(AuthToken.jwt?(subject)).to be true
    end

    it "sets expiration to 24 hours" do
      decoded = AuthToken.decode(subject).first

      expect(decoded['exp']).to be_within(5.seconds).of(24.hours.from_now.to_i)
    end
  end

  describe 'expiration' do
    subject { described_class.new.expiration }

    it "equals 24 hours from now" do
      travel_to Time.now do
        expect(subject).to eq 24.hours.from_now
      end
    end
  end
end
