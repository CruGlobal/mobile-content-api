# frozen_string_literal: true

class ViewsController < ApplicationController
  def create
    View.create!(permit_params(:quantity, :resource_id))
    head :no_content
  end
end
