# frozen_string_literal: true

class FollowUpsController < ApplicationController
  def create
    f = FollowUp.create!(permitted_params)
    f.send_to_api
    head :no_content
  end

  private

  def permitted_params
    permit_params(:email, :language_id, :destination_id, :name)
  end
end
