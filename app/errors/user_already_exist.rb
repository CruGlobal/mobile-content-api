# frozen_string_literal: true

module UserAlreadyExist
  class Error < StandardError
    def initialize(message = "User account already exists.")
      super(message)
    end
  end
end
