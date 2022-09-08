# frozen_string_literal: true

class UsersController < WithUserController
  def show
    render json: current_user
  end
end
