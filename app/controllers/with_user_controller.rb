# frozen_string_literal: true

class WithUserController < ApplicationController
  before_action :authorize!

  def authorize!
    # requested is authorized if using okta to provide a valid user id
    return if authorization && current_user

    render_unauthorized
  end
end
