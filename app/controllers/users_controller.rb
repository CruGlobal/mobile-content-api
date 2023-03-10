# frozen_string_literal: true

class UsersController < WithUserController
  def show
    render json: @user
  end

  def destroy
    @user.destroy!
    render json: "", status: 204
  end

  protected

  def user_id_attribute
    :id
  end
end
