# frozen_string_literal: true

class AccessCode < ActiveRecord::Base
  has_many :auth_tokens
end
