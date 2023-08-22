# frozen_string_literal: true

class UsersController < WithUserController
  before_action :get_user, only: [:update]

  def show
    render json: @user
  end

  def destroy
    @user.destroy!
    render json: "", status: 204
  end

  def update
    @user.set_arbitrary_attributes!(params["data"]["attributes"])

    render json: @user, status: :ok
  end

  protected

  def user_id_attribute
    :id
  end

  def get_user
    @user = User.find(params[:id])
  end
end
