# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def render(**args)
    if args.key? :json
      response.headers['Content-Type'] = 'application/vnd.api+json'
    end

    super
  end
end
