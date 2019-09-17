# frozen_string_literal: true

require "rails_helper"

describe Attribute do
  it "resource/key combination must be unique and is not case sensitive" do
    attr = described_class.create(resource_id: 1, key: "baNNer_IMage", value: "bar")

    expect(attr.errors[:resource]).to include "has already been taken"
  end

  it "key cannot end in underscore" do
    attr = described_class.create(resource_id: 1, key: "roger_", value: "test")

    expect(attr.errors[:key]).to include "is invalid"
  end

  it "key cannot have spaces" do
    attr = described_class.create(resource_id: 1, key: "roger the dog", value: "test")

    expect(attr.errors[:key]).to include "is invalid"
  end

  it "is only set to translatable if specified" do
    attr = described_class.create(resource_id: 1, key: "foo", value: "bar")

    expect(attr).to be_valid
    expect(attr.is_translatable).to be_falsey
  end
end
