# frozen_string_literal: true

require "ougai"
require File.expand_path("logger/formatter", __dir__)
require File.expand_path("logger/formatter_readable", __dir__)
module Log
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include ActiveSupport::LoggerSilence

    def initialize(*args)
      @readable = args[0] == $stdout
      super
    end

    def create_formatter
      if @readable
        Log::Logger::FormatterReadable.new($stdout)
      else
        Log::Logger::Formatter.new(ENV["PROJECT_NAME"])
      end
    end
  end
end
