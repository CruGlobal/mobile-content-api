# frozen_string_literal: true

class Destination < ActiveRecord::Base
  validates :url, presence: true
end
