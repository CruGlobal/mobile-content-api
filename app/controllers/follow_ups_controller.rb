# frozen_string_literal: true

class FollowUpsController < ApplicationController
  def create
    f = FollowUp.new(data_attrs[:email], data_attrs[:language_id], data_attrs[:destination_id], data_attrs[:name])

    if f.valid?
      response = f.send_to_api
      if response == 201
        head :no_content
      else
        f.errors.add(:id, "Received response code: #{response} from destination: #{f.destination.id}")
        render_error(f, :bad_request)
      end
    else
      render_error(f, :bad_request)
    end
  end
end
