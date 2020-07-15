# frozen_string_literal: true

class System < ActiveRecord::Base
  has_many :resources

  # validates :name, presence: true, uniqueness: true
end
