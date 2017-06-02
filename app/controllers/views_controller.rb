# frozen_string_literal: true

class ViewsController < ApplicationController
  def create
    View.create!(data_attrs.permit(:quantity, :resource_id))
    head :no_content
  end
end
