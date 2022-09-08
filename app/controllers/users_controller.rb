# frozen_string_literal: true

class UsersController < WithUserController
  prepend_before_action do set_user(:id); end

  def show
    render json: @user
  end
end
