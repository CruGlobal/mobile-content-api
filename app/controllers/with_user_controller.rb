# frozen_string_literal: true

class WithUserController < ApplicationController
  before_action :authorize!

  def authorize!
    # requested is authorized if using okta to provide a valid user id, and no specific user is set
    return if authorization && current_user && !@user

    # currently, if trying to operate on a specific @user, you can only operate on your own user data, but this may change later
    return if @user && @user == current_user

    render_unauthorized
  end

  def set_user(user_id_attribute = :user_id)
    @user = params[user_id_attribute].blank? || params[user_id_attribute] == "me" ? current_user : User.find(params[user_id_attribute])
  end
end
