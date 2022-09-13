# frozen_string_literal: true

class UsersController < WithUserController
  prepend_before_action { set_user(:id) }

  def show
    render json: @user
  end
end
