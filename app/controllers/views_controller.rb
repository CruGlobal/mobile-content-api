# frozen_string_literal: true

class ViewsController < ApplicationController
  def create
    params = permit_params(:quantity, :resource_id).to_h.symbolize_keys
    View.create!(**params)
    head :no_content
  end
end
