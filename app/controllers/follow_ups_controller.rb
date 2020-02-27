# frozen_string_literal: true

class FollowUpsController < ApplicationController
  def create
    f = FollowUp.create!(permitted_params)
    f.send_to_api
    head :no_content
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    raise e
  end

  private

  def permitted_params
    permit_params(:email, :language_id, :destination_id, :name)
  end
end
