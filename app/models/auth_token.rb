# frozen_string_literal: true

class AuthToken < ActiveRecord::Base
  belongs_to :access_code
end
