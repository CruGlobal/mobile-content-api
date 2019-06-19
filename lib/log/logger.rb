# frozen_string_literal: true
require 'ougai'
require File.expand_path('logger/formatter', __dir__)
require File.expand_path('logger/formatter_readable', __dir__)
module Log
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include LoggerSilence

    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def create_formatter
      if Rails.env.development? || Rails.env.test?
        Log::Logger::FormatterReadable.new(STDOUT)
      else
        Log::Logger::Formatter.new(ENV['PROJECT_NAME'])
      end
    end
  end
end
