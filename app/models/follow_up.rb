# frozen_string_literal: true

require 'rest-client'

class FollowUp
  include ActiveModel::Validations

  attr_accessor :email, :name, :language, :destination

  validates :email, presence: true, email_format: { message: 'Invalid email address' }
  validates :language, presence: true
  validates :destination, presence: true

  def initialize(email, language_id, destination_id, name = nil)
    self.email = email
    self.language = Language.find(language_id)
    self.destination = Destination.find(destination_id)
    self.name = name
  end

  def send_to_api
    validate_fields

    Rails.logger.info 'Sending request to destination'
    code = RestClient.post(destination.url, body, headers).code
    raise Error::BadRequestError, "Received response code: #{code} from destination: #{destination.id}" if code != 201
  end

  private

  def validate_fields
    raise Error::BadRequestError, errors.full_messages.join(', ') unless valid?
  end

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
end
