# frozen_string_literal: true

class FollowUpsController < ApplicationController
  def create
    FollowUp.new(data_attrs[:email], data_attrs[:language_id], data_attrs[:name])
    head :no_content
  end
end
