# frozen_string_literal: true

require 'rails_helper'

describe AccessCode do
  it 'sets expiration to 7 days after creation' do
    time = DateTime.current
    allow(DateTime).to receive(:now).and_return(time)

    result = AccessCode.create(code: 111_111)

    expect(result.expiration).to eq(time + 7.days)
  end
end
