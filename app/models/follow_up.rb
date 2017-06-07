# frozen_string_literal: true

require 'rest-client'

class FollowUp
  include ActiveModel::Validations

  attr_accessor :email, :name, :language, :destination

  validates :email, presence: true # TODO: validate content
  validates :language, presence: true
  validates :destination, presence: true

  def initialize(email, language_id, destination_id, name = nil)
    self.email = email
    self.language = Language.find(language_id)
    self.destination = Destination.find(destination_id)
    self.name = name
  end

  def send_to_api
    response = RestClient.post(destination.url, body, 'Access-Id': destination.access_key_id,
                                                      'Access-Secret': destination.access_key_secret,
                                                      'Content-Type': 'application/x-www-form-urlencoded')
    response.code
  end

  private

  def body
    names = name.split(' ')

    "subscriber[route_id]=#{destination.route_id}&subscriber[language_code]=#{language.code}"\
    "&subscriber[first_name]=#{names[0]}&subscriber[last_name]=#{names[1]}&subscriber[email]=#{email}"
  end
end
