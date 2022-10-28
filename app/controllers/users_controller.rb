# frozen_string_literal: true

class UsersController < WithUserController
  def show
    render json: @user
  end

  def destroy
    @user.user_counters.destroy_all
    @user.favorite_tools.destroy_all
    render json: "", status: 204
  end

  protected

  def user_id_attribute
    :id
  end
end
