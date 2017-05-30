# frozen_string_literal: true

require 'rails_helper'

describe ResourceType do
  it 'must have a valid DTD file' do
    name = 'test resource type'

    expect { described_class.create!(name: name, dtd_file: 'blah.xsd') }
      .to raise_error("ResourceType with name: #{name} does not have valid DTD file in 'public/xmlns/'.")
  end
end
