# frozen_string_literal: true

class UserCountersController < WithUserController
  def update
    counter = current_user.user_counters.where(counter_name: counter_name).first_or_initialize
    increment = permitted_params[:increment].to_f
    counter.count += increment
    counter.decay unless counter.new_record?
    counter.decayed_count += increment
    counter.save!
    render json: counter, status: :ok
  end

  def index
    counters = current_user.user_counters.where(counter_name: counter_name)
    render json: counters, status: ok
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
