# frozen_string_literal: true

class WithUserController < ApplicationController
  before_action :authorize!

  def authorize!
    # requested is authorized if using okta to provide a valid user id
    return if authorization && current_user

    # currently, if trying to operate on a specific @user, you can only operate on your own user data, but this may change later
    return if @user && @user == current_user

    render_unauthorized
  end

  def set_user
    @user = params[:user_id].blank? || params[:user_id] == "me" ? current_user : User.find(params[:user_id])
  end
end
