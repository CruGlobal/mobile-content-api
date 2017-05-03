# frozen_string_literal: true

class View < ActiveRecord::Base
  belongs_to :resource

  validates :quantity, presence: true
  validates :resource, presence: true
end
