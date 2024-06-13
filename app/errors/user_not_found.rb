# frozen_string_literal: true

module UserNotFound
  class Error < StandardError
    def initialize(message = "User account not found.")
      super
    end
  end
end
