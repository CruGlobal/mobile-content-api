# frozen_string_literal: true

module UserNotFound
  class Error < StandardError
    attr_reader :code

    def initialize(message = "User account not found.")
      super(message)
      @code = "user_not_found"
    end
  end
end