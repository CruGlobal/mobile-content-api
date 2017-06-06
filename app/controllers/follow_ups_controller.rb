# frozen_string_literal: true

class FollowUpsController < ApplicationController
  def create
    f = FollowUp.new(data_attrs[:email], data_attrs[:language_id], data_attrs[:name])

    if f.valid?
      f.send_to_api
      head :no_content
    else
      render_error(f, :bad_request)
    end
  end
end
