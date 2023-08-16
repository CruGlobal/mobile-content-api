# frozen_string_literal: true

module UserAlreadyExist
  class Error < StandardError
    attr_reader :code

    def initialize(message = "User account already exists.")
      super(message)
      @code = "user_already_exists"
    end
  end
end
