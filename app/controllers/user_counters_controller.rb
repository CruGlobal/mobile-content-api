# frozen_string_literal: true

class UserCountersController < WithUserController
  def update
    counter = current_user.user_counters.where(counter_name: counter_name).first_or_initialize
    counter.count ||= 0
    counter.count += permitted_params[:increment].to_f
    counter.save!
    render json: counter, status: :ok
  end

  protected

  def permitted_params
    params.require(:data).require(:attributes).permit(:increment)
  end

  def counter_name
    counter_name = params[:id]
    counter_name += ".#{params[:format]}" if params[:format].present?
    counter_name
  end
end
