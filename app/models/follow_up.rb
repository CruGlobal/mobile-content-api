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
    params = "subscriber[route_id]=#{destination.route_id}&subscriber[language_code]=#{language.code}"\
    "&subscriber[email]=#{email}#{names}"

    Rails.logger.info "Request body: #{params}"

    "#{params}#{auth_params}"
  end

  def names
    return nil if name.nil?

    names = name.split(' ')
    "&subscriber[first_name]=#{names[0]}&subscriber[last_name]=#{names[1]}"
  end

  def auth_params
    "&access_id=#{destination.access_key_id}&access_secret=#{destination.access_key_secret}"
  end

  def headers
    { 'Content-Type': 'application/x-www-form-urlencoded' }
  end

  def perform_request
    response = RestClient.post(destination.url, body, headers)
    code = response.code

    Rails.logger.info "Received response code: #{code} from destination: #{destination.id}"
    Rails.logger.info response
    
    raise Error::BadRequestError, "Received response code: #{code} from destination: #{destination.id}" if code != 201
  end
end
