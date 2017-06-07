# frozen_string_literal: true

require 'rest-client'

module OneskyUtil
  def self.handle(lambda)
    lambda.call
  rescue RestClient::BadRequest => e
    meta = JSON.parse(e.response)['meta']
    raise Error::BadRequestError, "OneSky returned code: #{meta['status']} with message: #{meta['message']}"
  end
end
