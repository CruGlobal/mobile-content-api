# frozen_string_literal: true

class AccessCode < ActiveRecord::Base
  has_many :auth_tokens

  validates :code, presence: true
end
