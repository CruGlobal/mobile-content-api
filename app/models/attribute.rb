# frozen_string_literal: true

class Attribute < BaseAttribute
  validates :resource, presence: true, uniqueness: {scope: :key}
end
