# frozen_string_literal: true

module UserNotFound
  class Error < StandardError
    def initialize(message = "User account not found.")
      super(message)
    end
  end
end
