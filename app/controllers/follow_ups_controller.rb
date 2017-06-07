# frozen_string_literal: true

class FollowUpsController < ApplicationController
  def create
    f = FollowUp.new(data_attrs[:email], data_attrs[:language_id], data_attrs[:destination_id], data_attrs[:name])
    f.send_to_api
    head :no_content
  end
end
