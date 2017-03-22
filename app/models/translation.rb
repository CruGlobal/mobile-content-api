# frozen_string_literal: true

class Translation < ActiveRecord::Base
  belongs_to :resource
end
