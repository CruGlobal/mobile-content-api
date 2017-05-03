# frozen_string_literal: true

class Stat < ActiveRecord::Base
  belongs_to :resource

  validates :quantity, presence: true
  validates :resource, presence: true
end
