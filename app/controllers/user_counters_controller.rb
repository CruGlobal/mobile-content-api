# frozen_string_literal: true

class UserCountersController < WithUserController
  prepend_before_action :set_user

  def update
    counter = @user.user_counters.where(counter_name: counter_name).first_or_initialize
    increment = permitted_params[:increment].to_f
    counter.count += increment
    counter.decay
    counter.decayed_count += increment
    counter.save!
    render json: counter, status: :ok
  end

  def index
    counters = @user.user_counters
    # decay but don't save as it's not needed and it'll be more efficient this way -- the in-memory decay calculation is very fast
    counters.each(&:decay)
    render json: counters, status: :ok
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
