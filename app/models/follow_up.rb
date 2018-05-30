# frozen_string_literal: true

require 'rest-client'

class FollowUp < ActiveRecord::Base
  belongs_to :language
  belongs_to :destination

  validates :email, presence: true, email_format: { message: 'Invalid email address' }
  validates :language, presence: true
  validates :destination, presence: true

  def send_to_api
    save! if changed?
    Rails.logger.info "Sending follow up with id: #{id}."
    perform_request
  end

  private

  def body
    "subscriber[route_id]=#{destination.route_id}&subscriber[language_code]=#{language.code}"\
    "&subscriber[email]=#{email}#{names}"
  end

  def names
    return nil if name.nil?

    names = name.split(' ')
    "&subscriber[first_name]=#{names[0]}&subscriber[last_name]=#{names[1]}"
  end

  def headers
    { 'Access-Id': destination.access_key_id,
      'Access-Secret': destination.access_key_secret,
      'Content-Type': 'application/x-www-form-urlencoded' }
  end

  def perform_request
    code = RestClient.post(destination.url, body, headers).code
    Rails.logger.info "Received response code: #{code} from destination: #{destination.id}"
    raise Error::BadRequestError, "Received response code: #{code} from destination: #{destination.id}" if code != 201
  end
end
