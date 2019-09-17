# frozen_string_literal: true

class View < ActiveRecord::Base
  belongs_to :resource

  validates :quantity, presence: true, numericality: {greater_than: 0}
  validates :resource, presence: true
end
