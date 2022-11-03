# frozen_string_literal: true

module Log
  class Logger < Ougai::Logger
    class Formatter < Ougai::Formatters::Bunyan
      def initialize(*args)
        super
      end

      def _call(severity, time, progname, data)
        request = data.delete(:request)
        if request
          data[:network] = {client: {ip: request.ip}}
          data[:amzn_trace_id] = request.headers["X-Amzn-Trace-Id"]
          data[:request_id] = request.uuid
        end

        dump({
          :name => progname || @app_name,
          :host => @hostname,
          :level => severity,
          :time => time,
          :env => Rails.env,
          "dd.trace_id" => Datadog::Tracing.correlation.trace_id,
          "dd.span_id" => Datadog::Tracing.correlation.span_id
        }.merge(data))
      end
    end
  end
end
