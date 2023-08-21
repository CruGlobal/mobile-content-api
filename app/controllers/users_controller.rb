# frozen_string_literal: true

class UsersController < WithUserController
  def show
    render json: @user
  end

  def destroy
    @user.destroy!
    render json: "", status: 204
  end

  def me
    @user.set_arbitrary_attributes!(params["data"]["attributes"])

    render json: @user, status: :created
  end

  protected

  def user_id_attribute
    :id
  end
end
